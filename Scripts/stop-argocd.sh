#!/bin/bash

set -e

echo "Deleting ArgoCD namespace..."

kubectl delete namespace argocd --ignore-not-found=true

echo ""
echo "ArgoCD removed successfully."