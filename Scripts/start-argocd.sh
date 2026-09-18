#!/bin/bash

set -e

echo "Creating ArgoCD namespace..."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD..."

kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Configuring ArgoCD for the Codespaces HTTPS tunnel..."
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd

echo "Waiting for ArgoCD pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo ""
echo "ArgoCD installation complete."
echo ""

ARGOCD_USERNAME="admin"
ARGOCD_PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)"

echo "Port forward command:"
echo "kubectl port-forward svc/argocd-server -n argocd 8081:80"

echo ""
echo "ArgoCD login credentials:"
echo "Username: ${ARGOCD_USERNAME}"
echo "Password: ${ARGOCD_PASSWORD}"