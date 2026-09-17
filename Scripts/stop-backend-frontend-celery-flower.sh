#!/bin/bash

set -e

echo "Deleting flask-app frontend-app flower celery-beat celery-worker..."

kubectl delete namespace flask-app frontend-app flower celery-beat celery-worker --ignore-not-found=true

echo ""
echo "flask-app frontend-app flower celery-beat celery-worker removed successfully."


