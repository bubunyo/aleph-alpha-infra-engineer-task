# Makefile for Guestbook Frontend

# Variables
PYTHON := python3
PIP := pip3
APP_NAME := python-guestbook-frontend
MAIN_FILE := front.py

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  install     - Install dependencies"
	@echo "  test        - Run tests"
	@echo "  lint        - Run code linting"
	@echo "  format      - Format code"
	@echo "  run         - Run the application locally"
	@echo "  clean       - Clean temporary files"
	@echo "  check       - Run all checks (test + lint)"

# Install dependencies
.PHONY: install
install:
	@echo "📦 Installing dependencies..."
	$(PIP) install -r requirements.txt

# Install development dependencies
.PHONY: install-dev
install-dev: install
	@echo "📦 Installing development dependencies..."
	$(PIP) install pytest pytest-cov flake8 black isort

# Run tests
.PHONY: test
test:
	@echo "🧪 Running tests..."
	@if [ -n "$$(find . -name '*test*.py' -o -name 'test_*.py' -o -name '*_test.py' 2>/dev/null)" ]; then \
		echo "Found test files, running pytest..."; \
		$(PYTHON) -m pytest -v --tb=short || (echo "❌ Tests failed" && exit 1); \
	fi

# Run linting
.PHONY: lint
lint:
	@echo "🔍 Running linting..."
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 --max-line-length=88 --ignore=E203,W503 *.py; \
	else \
		echo "⚠️  flake8 not installed, running syntax check instead..."; \
		$(PYTHON) -m py_compile $(MAIN_FILE); \
	fi

# Format code
.PHONY: format
format:
	@echo "🎨 Formatting code..."
	@if command -v black >/dev/null 2>&1; then \
		black *.py; \
	else \
		echo "⚠️  black not installed, skipping formatting"; \
	fi
	@if command -v isort >/dev/null 2>&1; then \
		isort *.py; \
	else \
		echo "⚠️  isort not installed, skipping import sorting"; \
	fi

# Run the application locally
.PHONY: run
run:
	@echo "🚀 Running $(APP_NAME)..."
	$(PYTHON) $(MAIN_FILE)

# Clean temporary files
.PHONY: clean
clean:
	@echo "🧹 Cleaning temporary files..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type f -name ".coverage" -delete

# Run all checks
.PHONY: check
check: lint test
	@echo "✅ All checks completed"

# Validate application can start
.PHONY: validate
validate:
	@echo "🔍 Validating application..."
	@$(PYTHON) -c "import $(MAIN_FILE)" 2>/dev/null && echo "✅ Application imports successfully" || echo "❌ Application import failed"

# Check static files
.PHONY: check-static
check-static:
	@echo "🔍 Checking static assets..."
	@if [ -d "static" ]; then \
		echo "✅ Static directory found"; \
		ls -la static/; \
	else \
		echo "⚠️  No static directory found"; \
	fi
	@if [ -d "templates" ]; then \
		echo "✅ Templates directory found"; \
		ls -la templates/; \
	else \
		echo "⚠️  No templates directory found"; \
	fi