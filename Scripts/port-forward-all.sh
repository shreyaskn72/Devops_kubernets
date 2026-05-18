#!/bin/bash

set -e

mkdir -p logs

echo "========================================="
echo "Starting Port Forwards"
echo "========================================="

timestamp=$(date +"%Y-%m-%d %H:%M:%S")

echo "" >> logs/argocd-portforward.log
echo "===== $timestamp =====" >> logs/argocd-portforward.log

echo "" >> logs/flask-api-portforward.log
echo "===== $timestamp =====" >> logs/flask-api-portforward.log

echo "" >> logs/react-portforward.log
echo "===== $timestamp =====" >> logs/react-portforward.log

echo "" >> logs/flower-portforward.log
echo "===== $timestamp =====" >> logs/flower-portforward.log

echo "" >> logs/rabbitmq-portforward.log
echo "===== $timestamp =====" >> logs/rabbitmq-portforward.log

echo ""
echo "Starting ArgoCD UI port forward..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 \
  >> logs/argocd-portforward.log 2>&1 &
echo "ArgoCD UI -> http://localhost:8080"

echo ""
echo "Starting Flask API port forward..."
kubectl port-forward svc/flask-api-flask-api -n flask-app 5000:80 \
  >> logs/flask-api-portforward.log 2>&1 &
echo "Flask API -> http://localhost:5000"

echo ""
echo "Starting React Frontend port forward..."
kubectl port-forward svc/react-frontend -n frontend-app 3000:80 \
  >> logs/react-portforward.log 2>&1 &
echo "React Frontend -> http://localhost:3000"

echo ""
echo "Starting Flower UI port forward..."
kubectl port-forward svc/flower-service -n flower 5555:5555 \
  >> logs/flower-portforward.log 2>&1 &
echo "Flower UI -> http://localhost:5555"

echo ""
echo "Starting RabbitMQ UI port forward..."
kubectl port-forward svc/rabbitmq -n messaging 15672:15672 \
  >> logs/rabbitmq-portforward.log 2>&1 &
echo "RabbitMQ UI -> http://localhost:15672"

echo ""
echo "========================================="
echo "All port forwards started."
echo "========================================="

echo ""
echo "Logs directory:"
echo "./logs"

echo ""
echo "To stop all port forwards:"
echo "pkill -f 'kubectl port-forward'"