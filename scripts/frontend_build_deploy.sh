#!/bin/bash
set -e  # Exit on any error

# Get git SHA for image tagging
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
REGISTRY="127.0.0.1:5000"

# Build the frontend component
./scripts/build.sh --component=frontend

# Deploy using Helm upgrade
helm upgrade guestbook-frontend ./infra/charts/guestbook-frontend \
  --namespace application \
  --set image.repository=${REGISTRY}/python-guestbook-frontend \
  --set image.tag=${GIT_SHA} \
  --reuse-values \
  --wait --timeout=300s

# Verify deployment
kubectl get pods -n application -l app.kubernetes.io/name=guestbook-frontend
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guestbook-frontend -n application --timeout=300s

echo "Frontend deployment completed successfully!"
