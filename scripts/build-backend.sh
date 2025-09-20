#!/bin/bash
set -e  # Exit on any error
./scripts/build.sh --component=backend

# Restart an existing deployment to pull the latest image
kubectl rollout restart deployment/guestbook-backend -n application

# Wait for the rollout to complete
kubectl rollout status deployment/guestbook-backend -n application