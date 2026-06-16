#!/bin/bash

set -e

echo "Deleting messaging namespace..."

kubectl delete namespace messaging --ignore-not-found=true

echo ""
echo "RabbitMQ removed successfully."