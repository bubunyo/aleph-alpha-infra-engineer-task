"""
A sample backend server. Saves and retrieves entries using mongodb
"""
import os
import time
from flask import Flask, jsonify, request
from flask_pymongo import PyMongo
import bleach
import psutil
from prometheus_client import Counter, Gauge, Histogram, generate_latest, CONTENT_TYPE_LATEST
from functools import wraps

app = Flask(__name__)
app.config["MONGO_URI"] = 'mongodb://{}/guestbook'.format(os.environ.get('GUESTBOOK_DB_ADDR'))
mongo = PyMongo(app)

# Prometheus metrics
messages_posted = Counter('guestbook_messages_posted_total', 'Total number of messages posted')
cpu_usage = Gauge('guestbook_cpu_usage_percent', 'CPU usage percentage')
memory_usage = Gauge('guestbook_memory_usage_bytes', 'Memory usage in bytes')
memory_total = Gauge('guestbook_memory_total_bytes', 'Total memory in bytes')
db_operations = Counter('guestbook_db_operations_total', 'Total database operations', ['operation'])

# HTTP metrics
http_requests_total = Counter('guestbook_http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
http_request_duration = Histogram('guestbook_http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint'])

def track_metrics(endpoint_name):
    """ Decorator to track HTTP request metrics """
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            method = request.method
            status = '500'  # default to error
            
            try:
                result = f(*args, **kwargs)
                # Extract status code from response tuple or assume 200
                if isinstance(result, tuple):
                    status = str(result[1])
                else:
                    status = '200'
                return result
            except Exception as e:
                status = '500'
                raise e
            finally:
                # Record metrics
                duration = time.time() - start_time
                http_request_duration.labels(method=method, endpoint=endpoint_name).observe(duration)
                http_requests_total.labels(method=method, endpoint=endpoint_name, status=status).inc()
        
        return wrapper
    return decorator

@app.route('/messages', methods=['GET'])
@track_metrics('messages')
def get_messages():
    """ retrieve and return the list of messages on GET request """
    field_mask = {'author':1, 'message':1, 'date':1, '_id':0}
    msg_list = list(mongo.db.messages.find({}, field_mask).sort("_id", -1))
    db_operations.labels(operation='read').inc()
    return jsonify(msg_list), 201

@app.route('/messages', methods=['POST'])
@track_metrics('messages')
def add_message():
    """ save a new message on POST request """
    raw_data = request.get_json()
    msg_data = {'author':bleach.clean(raw_data['author']),
                'message':bleach.clean(raw_data['message']),
                'date':time.time()}
    mongo.db.messages.insert_one(msg_data)
    messages_posted.inc()
    db_operations.labels(operation='write').inc()
    return  jsonify({}), 201

@app.route('/health', methods=['GET'])
@track_metrics('health')
def health_check():
    """ Health check endpoint for liveness probe """
    return jsonify({"status": "healthy", "timestamp": time.time()}), 200

@app.route('/ready', methods=['GET'])
@track_metrics('ready')
def readiness_check():
    """ Readiness check endpoint - checks if database is accessible """
    try:
        # Test database connection
        mongo.db.messages.find_one()
        return jsonify({"status": "ready", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "not ready", "error": str(e)}), 503

@app.route('/metrics', methods=['GET'])
def metrics():
    """ Prometheus metrics endpoint using prometheus_client """
    try:
        # Update system metrics
        cpu_percent = psutil.cpu_percent()
        memory = psutil.virtual_memory()
        
        cpu_usage.set(cpu_percent)
        memory_usage.set(memory.used)
        memory_total.set(memory.total)
        
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
    except Exception as e:
        return f"# Error getting metrics: {str(e)}", 500, {'Content-Type': 'text/plain; charset=utf-8'}

if __name__ == '__main__':
    for v in ['PORT', 'GUESTBOOK_DB_ADDR']:
        if os.environ.get(v) is None:
            print("error: {} environment variable not set".format(v))
            exit(1)

    # start Flask server
    # Flask's debug mode is unrelated to ptvsd debugger used by Cloud Code
    app.run(debug=False, port=os.environ.get('PORT'), host='0.0.0.0')
