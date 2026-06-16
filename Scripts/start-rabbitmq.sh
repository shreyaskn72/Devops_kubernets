#!/bin/bash

set -e

echo "Creating messaging namespace..."

kubectl create namespace messaging --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying RabbitMQ..."

kubectl apply -f ../helm/values-rabbitmq.yaml

echo "Waiting for RabbitMQ pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n messaging --timeout=300s

echo ""
echo "RabbitMQ deployment complete."
echo ""

echo "RabbitMQ UI port-forward command:"
echo "kubectl port-forward svc/rabbitmq 15672:15672 -n messaging"

echo ""
echo "RabbitMQ broker port-forward command:"
echo "kubectl port-forward svc/rabbitmq 5672:5672 -n messaging"