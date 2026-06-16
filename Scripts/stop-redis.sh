#!/bin/bash

set -e

echo "Deleting cache namespace..."

kubectl delete namespace cache --ignore-not-found=true

echo ""
echo "Redis removed successfully."