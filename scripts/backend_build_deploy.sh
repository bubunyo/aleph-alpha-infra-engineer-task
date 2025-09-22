#!/bin/bash
set -e  # Exit on any error

# Get git SHA for image tagging
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
REGISTRY="127.0.0.1:5000"

# Build the backend component
./scripts/build.sh --component=backend

# Deploy using Helm upgrade
helm upgrade guestbook-backend ./infra/charts/guestbook-backend \
  --namespace application \
  --set image.repository=${REGISTRY}/python-guestbook-backend \
  --set image.tag=${GIT_SHA} \
  --reuse-values \
  --wait --timeout=300s

# Verify deployment
kubectl get pods -n application -l app.kubernetes.io/name=guestbook-backend
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=guestbook-backend -n application --timeout=300s

echo "Backend deployment completed successfully!"