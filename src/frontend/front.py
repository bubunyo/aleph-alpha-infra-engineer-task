"""
A sample frontend server. Hosts a web page to display messages
"""
import json
import os
import datetime
import time
from flask import Flask, render_template, redirect, url_for, request, jsonify
import requests
import dateutil.relativedelta
import psutil
from prometheus_client import Counter, Gauge, Histogram, generate_latest, CONTENT_TYPE_LATEST
from functools import wraps

app = Flask(__name__)
app.config["BACKEND_URI"] = 'http://{}/messages'.format(os.environ.get('GUESTBOOK_API_ADDR'))

# Prometheus metrics
page_views = Counter('guestbook_frontend_page_views_total', 'Total number of page views')
posts_submitted = Counter('guestbook_frontend_posts_submitted_total', 'Total number of posts submitted')
cpu_usage = Gauge('guestbook_frontend_cpu_usage_percent', 'CPU usage percentage')
memory_usage = Gauge('guestbook_frontend_memory_usage_bytes', 'Memory usage in bytes')
memory_total = Gauge('guestbook_frontend_memory_total_bytes', 'Total memory in bytes')
backend_available = Gauge('guestbook_frontend_backend_available', 'Backend availability (1=up, 0=down)')
backend_requests = Counter('guestbook_frontend_backend_requests_total', 'Total requests to backend', ['status'])

# HTTP metrics
http_requests_total = Counter('guestbook_frontend_http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
http_request_duration = Histogram('guestbook_frontend_http_request_duration_seconds', 'HTTP request latency', ['method', 'endpoint'])

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
                # For redirects, status is 302
                if hasattr(result, 'status_code'):
                    status = str(result.status_code)
                elif isinstance(result, tuple):
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

@app.route('/')
@track_metrics('home')
def main():
    """ Retrieve a list of messages from the backend, and use them to render the HTML template """
    page_views.inc()
    try:
        response = requests.get(app.config["BACKEND_URI"], timeout=3)
        backend_requests.labels(status=str(response.status_code)).inc()
        json_response = json.loads(response.text)
        return render_template('home.html', messages=json_response)
    except Exception as e:
        backend_requests.labels(status='error').inc()
        return render_template('home.html', messages=[], error=str(e))

@app.route('/post', methods=['POST'])
@track_metrics('post')
def post():
    """ Send the new message to the backend and redirect to the homepage """
    new_message = {'author': request.form['name'],
                   'message':  request.form['message']}
    try:
        response = requests.post(url=app.config["BACKEND_URI"],
                      data=jsonify(new_message).data,
                      headers={'content-type': 'application/json'},
                      timeout=3)
        backend_requests.labels(status=str(response.status_code)).inc()
        posts_submitted.inc()
    except Exception as e:
        backend_requests.labels(status='error').inc()
    return redirect(url_for('main'))

def format_duration(timestamp):
    """ Format the time since the input timestamp in a human readable way """
    now = datetime.datetime.fromtimestamp(time.time())
    prev = datetime.datetime.fromtimestamp(timestamp)
    rd = dateutil.relativedelta.relativedelta(now, prev)

    for n, unit in [(rd.years, "year"), (rd.days, "day"), (rd.hours, "hour"),
                    (rd.minutes, "minute")]:
        if n == 1:
            return "{} {} ago".format(n, unit)
        elif n > 1:
            return "{} {}s ago".format(n, unit)
    return "just now"

@app.route('/health', methods=['GET'])
@track_metrics('health')
def health_check():
    """ Health check endpoint for liveness probe """
    return jsonify({"status": "healthy", "timestamp": time.time()}), 200

@app.route('/ready', methods=['GET'])
@track_metrics('ready')
def readiness_check():
    """ Readiness check endpoint - checks if backend is accessible """
    try:
        # Test backend connection
        response = requests.get(app.config["BACKEND_URI"], timeout=3)
        if response.status_code == 201:
            return jsonify({"status": "ready", "backend": "connected"}), 200
        else:
            return jsonify({"status": "not ready", "backend": "error", "status_code": response.status_code}), 503
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
        
        # Update backend availability
        try:
            response = requests.get(app.config["BACKEND_URI"], timeout=2)
            backend_available.set(1 if response.status_code == 200 else 0)
        except:
            backend_available.set(0)
        
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
    except Exception as e:
        return f"# Error getting metrics: {str(e)}", 500, {'Content-Type': 'text/plain; charset=utf-8'}

if __name__ == '__main__':
    for v in ['PORT', 'GUESTBOOK_API_ADDR']:
        if os.environ.get(v) is None:
            print("error: {} environment variable not set".format(v))
            exit(1)

    # register format_duration for use in html template
    app.jinja_env.globals.update(format_duration=format_duration)

    # start Flask server
    # Flask's debug mode is unrelated to ptvsd debugger used by Cloud Code
    app.run(debug=False, port=os.environ.get('PORT'), host='0.0.0.0')
