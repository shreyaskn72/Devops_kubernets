#!/bin/bash

# ============================================================
# Option 2: Quick Start - Local MySQL + Kubernetes
# ============================================================

echo "🚀 Starting Option 2 Setup..."
echo ""

# Step 1: Start MySQL
echo "📦 Starting MySQL Container..."
docker run -d \
  --name local-mysql \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=flask_app \
  -e MYSQL_USER=flask_user \
  -e MYSQL_PASSWORD=flask_password \
  -p 3306:3306 \
  mysql:8.0

echo "⏳ Waiting for MySQL to be ready..."
sleep 15

echo "✅ MySQL Started"
echo "   Connection: localhost:3306"
echo "   User: flask_user"
echo "   Password: flask_password"
echo ""

# Step 2: Create namespace
echo "📦 Creating Kubernetes Namespace..."
kubectl create namespace flask-app --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace created"
echo ""

# Step 3: Deploy with Helm
echo "📦 Deploying Flask API with Helm..."
helm install flask-api ./flask_api/helm/flask-api \
  -n flask-app \
  -f ./flask_api/helm/flask-api/values.yaml

echo ""
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flask-api -n flask-app --timeout=300s 2>/dev/null

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "======================================================"
echo "📝 Next Steps:"
echo "======================================================"
echo ""
echo "1. Open a NEW terminal and run:"
echo "   kubectl port-forward svc/flask-api 5000:80 -n flask-app"
echo ""
echo "2. Test the API:"
echo "   curl http://localhost:5000/health"
echo ""
echo "3. View logs:"
echo "   kubectl logs -f deployment/flask-api -n flask-app"
echo ""
echo "4. Create a user:"
echo "   curl -X POST http://localhost:5000/api/users \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"name\":\"John\",\"email\":\"john@example.com\",\"city\":\"NYC\",\"age\":30}'"
echo ""
echo "======================================================"
echo "📊 Current Status:"
echo "======================================================"
kubectl get pods -n flask-app
echo ""
echo "Services:"
kubectl get svc -n flask-app
echo ""

