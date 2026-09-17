#!/bin/bash

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

echo "Creating cache namespace..."

kubectl create namespace cache --dry-run=client -o yaml | kubectl apply -f -

echo "Adding Bitnami Helm repository..."

helm repo add bitnami https://charts.bitnami.com/bitnami || true

helm repo update

echo "Installing Redis..."

if kubectl get pvc -n cache redis-data-redis-master-0 \
    -o jsonpath='{.spec.storageClassName}' 2>/dev/null | grep -qx 'hostpath'; then
    echo "Removing the pending Redis PVC created with the unavailable hostpath StorageClass..."
    helm uninstall redis -n cache >/dev/null 2>&1 || true
    kubectl delete pvc redis-data-redis-master-0 -n cache --ignore-not-found=true
fi

helm upgrade --install redis bitnami/redis \
  -n cache \
  -f "$REPO_ROOT/helm/values-redis.yaml"

echo "Waiting for Redis pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n cache --timeout=300s

echo ""
echo "Redis installation complete."
echo ""

echo "Redis port-forward command:"
echo "kubectl port-forward svc/redis-master 6379:6379 -n cache"