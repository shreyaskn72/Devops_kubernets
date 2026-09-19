#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGMAP_ENV_FILE="$ROOT_DIR/.devcontainer/.env.configmap"
SECRET_ENV_FILE="$ROOT_DIR/.devcontainer/.env.secret"

for namespace in flask-app celery-worker celery-beat flower frontend-app; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

if [ ! -f "$CONFIGMAP_ENV_FILE" ]; then
  echo "Missing ConfigMap env file: $CONFIGMAP_ENV_FILE" >&2
  exit 1
fi

for namespace in flask-app celery-worker celery-beat flower frontend-app; do
  kubectl create configmap app-config \
    --from-env-file="$CONFIGMAP_ENV_FILE" \
    -n "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

if [ ! -f "$SECRET_ENV_FILE" ]; then
  echo "Missing Secret env file: $SECRET_ENV_FILE" >&2
  exit 1
fi

for namespace in flask-app celery-worker celery-beat flower; do
  kubectl create secret generic app-secret \
    --from-env-file="$SECRET_ENV_FILE" \
    -n "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

chmod +x Scripts/*.sh
cd "$ROOT_DIR/Scripts"
bash ./start-mysql.sh

# retry start-argocd up to 3 times
set +e
try=0
max=3
ok=0
until [ $try -ge $max ]; do
  bash ./start-argocd.sh && { ok=1; break; } || {
    try=$((try+1))
    echo "start-argocd attempt $try/$max failed"
    sleep 5
  }
done
set -e
if [ $ok -ne 1 ]; then
  echo "start-argocd failed after $max attempts"
  exit 1
fi

kubectl wait --for=condition=Available --all deployments -n argocd --timeout=300s

bash ./start-rabbitmq.sh
kubectl wait --for=condition=Available --all deployments -n messaging --timeout=300s

if helm status redis -n cache >/dev/null 2>&1; then
  kubectl wait --for=condition=Ready pods --all -n cache --timeout=300s
else
  bash ./start-redis.sh
fi

until bash ./start_frontend_backend_celery_flower.sh; do
  echo "Application resources are still being created; retrying in 10 seconds..."
  sleep 10
done

for namespace in flask-app celery-worker celery-beat flower frontend-app; do
  kubectl rollout restart deployment --all -n "$namespace"
  kubectl rollout status deployment --all -n "$namespace" --timeout=300s
done


echo ""
echo ""
echo "========================================="
echo "run ./port-forward-all.sh inside Scripts folder to start port-forwarding"
echo "========================================="

