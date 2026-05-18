#!/bin/bash

set -e

echo "Creating cache namespace..."

kubectl create namespace cache --dry-run=client -o yaml | kubectl apply -f -

echo "Adding Bitnami Helm repository..."

helm repo add bitnami https://charts.bitnami.com/bitnami || true

helm repo update

echo "Installing Redis..."

helm install redis bitnami/redis \
  -n cache \
  -f ../helm/values-redis.yaml

echo "Waiting for Redis pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n cache --timeout=300s

echo ""
echo "Redis installation complete."
echo ""

echo "Redis port-forward command:"
echo "kubectl port-forward svc/redis-master 6379:6379 -n cache"