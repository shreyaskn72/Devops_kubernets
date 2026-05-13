#!/bin/bash

# ============================================================
# LOCAL MySQL + Kubernetes (Docker Desktop) Deployment Script
# Option 2: Local MySQL Database
# ============================================================

echo "🚀 Flask API + Local MySQL Setup for Docker Desktop"
echo "======================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Start Local MySQL
echo -e "${BLUE}Step 1: Starting Local MySQL on Docker Desktop${NC}"
echo "Starting MySQL container on localhost:3306..."
echo ""

docker run -d \
  --name local-mysql \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=flask_app \
  -e MYSQL_USER=flask_user \
  -e MYSQL_PASSWORD=flask_password \
  -p 3306:3306 \
  mysql:8.0

echo -e "${GREEN}✓ MySQL Container Started${NC}"
echo ""
echo "MySQL Connection Details:"
echo "  Host: localhost:3306"
echo "  User: flask_user"
echo "  Password: flask_password"
echo "  Database: flask_app"
echo ""

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
sleep 10

# Step 2: Verify MySQL Connection
echo -e "${BLUE}Step 2: Verifying MySQL Connection${NC}"
docker exec local-mysql mysql -uflask_user -pflask_password flask_app -e "SELECT 1;" 2>/dev/null
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ MySQL is Ready${NC}"
else
  echo -e "${YELLOW}⚠ MySQL connection failed, waiting a bit more...${NC}"
  sleep 5
fi
echo ""

# Step 3: Verify Kubernetes Context
echo -e "${BLUE}Step 3: Checking Kubernetes Context${NC}"
CONTEXT=$(kubectl config current-context)
echo "Current Context: $CONTEXT"

if [[ "$CONTEXT" == *"docker-desktop"* ]]; then
  echo -e "${GREEN}✓ Docker Desktop Kubernetes Detected${NC}"
else
  echo -e "${YELLOW}⚠ Warning: You may not be using Docker Desktop Kubernetes${NC}"
  echo "  If you're using Minikube, replace 'host.docker.internal' with 'host.minikube.internal'"
fi
echo ""

# Step 4: Create Namespace
echo -e "${BLUE}Step 4: Creating Kubernetes Namespace${NC}"
kubectl create namespace flask-app --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace 'flask-app' Ready${NC}"
echo ""

# Step 5: Deploy Flask API with Helm
echo -e "${BLUE}Step 5: Deploying Flask API with Helm${NC}"
echo "Deploying to Kubernetes..."
echo ""

helm install flask-api ./flask_api/helm/flask-api \
  -n flask-app \
  -f ./flask_api/helm/flask-api/values.yaml

echo ""
echo -e "${GREEN}✓ Helm Chart Installed${NC}"
echo ""

# Step 6: Wait for pods to be ready
echo -e "${BLUE}Step 6: Waiting for Pods to Start${NC}"
echo "This may take a minute..."
kubectl wait --for=condition=ready pod -l app=flask-api -n flask-app --timeout=300s

echo -e "${GREEN}✓ All Pods are Ready${NC}"
echo ""

# Step 7: Port Forward
echo -e "${BLUE}Step 7: Setting Up Port Forwarding${NC}"
echo "Pod port forwarding to localhost:5000"
echo ""
echo "In a new terminal, run:"
echo -e "${YELLOW}kubectl port-forward svc/flask-api 5000:80 -n flask-app${NC}"
echo ""
echo "Or I can do it for you. Press Enter to start port-forward, or Ctrl+C to skip:"
read -r

kubectl port-forward svc/flask-api 5000:80 -n flask-app

echo ""
echo "======================================================"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo "======================================================"
echo ""
echo "API is now available at: http://localhost:5000"
echo ""
echo "Test it:"
echo "  curl http://localhost:5000/health"
echo "  curl http://localhost:5000/"
echo ""
echo "Create a user:"
echo "  curl -X POST http://localhost:5000/api/users \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"name\":\"John\",\"email\":\"john@example.com\",\"city\":\"NYC\",\"age\":30}'"
echo ""
echo "Cleanup when done:"
echo "  helm uninstall flask-api -n flask-app"
echo "  docker stop local-mysql && docker rm local-mysql"
echo ""

