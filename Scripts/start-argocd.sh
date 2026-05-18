#!/bin/bash

set -e

echo "Creating ArgoCD namespace..."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD..."

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo ""
echo "ArgoCD installation complete."
echo ""

echo "Port forward command:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"

echo ""
echo "Admin password command:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"