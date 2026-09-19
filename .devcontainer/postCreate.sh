#!/usr/bin/env bash
set -e

mkdir -p "/home/vscode/.kube"
mkdir -p "$HOME/.kube"

if ! kubectl cluster-info >/dev/null 2>&1; then
  kind get clusters | grep -qx dev-cluster || kind create cluster --name dev-cluster
fi

CLUSTER=$(kind get clusters | head -n1)
KUBECONFIG_PATH="/home/vscode/.kube/config"

if kind get kubeconfig --name "$CLUSTER" >/dev/null 2>&1; then
  kind get kubeconfig --name "$CLUSTER" > "$KUBECONFIG_PATH"
elif [ -f "$HOME/.kube/config" ]; then
  cp -f "$HOME/.kube/config" "$KUBECONFIG_PATH"
fi

chown -R vscode:vscode /home/vscode/.kube || true
export KUBECONFIG="$KUBECONFIG_PATH"
CONTEXT="kind-$CLUSTER"
kubectl config use-context "$CONTEXT" || true

# Create ConfigMap and Secret from env files for local development
for namespace in flask-app celery-worker celery-beat flower frontend-app; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

if [ -f ".devcontainer/.env.configmap" ]; then
  echo "Creating K8s ConfigMap from .env.configmap..."
  for namespace in flask-app celery-worker celery-beat flower frontend-app; do
    kubectl create configmap app-config \
      --from-env-file=.devcontainer/.env.configmap \
      -n "$namespace" --dry-run=client -o yaml | kubectl apply -f -
  done
  echo "ConfigMap 'app-config' created/updated successfully"
fi

if [ -f ".devcontainer/.env.secret" ]; then
  echo "Creating K8s Secret from .env.secret..."
  for namespace in flask-app celery-worker celery-beat flower; do
    kubectl create secret generic app-secret \
      --from-env-file=.devcontainer/.env.secret \
      -n "$namespace" --dry-run=client -o yaml | kubectl apply -f -
  done
  echo "Secret 'app-secret' created/updated successfully"
fi

chmod +x Scripts/*.sh
cd Scripts

./start-mysql.sh

# retry start-argocd up to 3 times
set +e
try=0
max=3
ok=0
until [ $try -ge $max ]; do
  ./start-argocd.sh && { ok=1; break; } || {
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

kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s

./start-rabbitmq.sh
kubectl wait --for=condition=Available deployment --all -n messaging --timeout=300s

if helm status redis -n cache >/dev/null 2>&1; then
  kubectl wait --for=condition=Ready pods --all -n cache --timeout=300s
else
  ./start-redis.sh
fi

until ./start_frontend_backend_celery_flower.sh; do
  echo "Application resources are still being created; retrying in 10 seconds..."
  sleep 10
done

# Port-forwarding is started via devcontainer `postStartCommand` to ensure it
# runs on each container start/reopen. Do not start port-forwards here.
