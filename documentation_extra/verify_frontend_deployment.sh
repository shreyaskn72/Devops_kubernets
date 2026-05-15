#!/bin/bash

# Frontend Deployment Verification Script
# This script verifies all components are in place for deployment

echo "🔍 Frontend Deployment Verification"
echo "===================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check Helm files
echo "📋 Checking Helm Chart Files..."
HELM_FILES=(
    "frontend_app/helm/react-frontend/Chart.yaml"
    "frontend_app/helm/react-frontend/values.yaml"
    "frontend_app/helm/react-frontend/templates/deployment.yaml"
    "frontend_app/helm/react-frontend/templates/service.yaml"
    "frontend_app/helm/react-frontend/templates/ingress.yaml"
    "frontend_app/helm/react-frontend/templates/helpers.tpl"
    "frontend_app/helm/react-frontend/templates/NOTES.txt"
)

for file in "${HELM_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file - MISSING"
        ((ERRORS++))
    fi
done

echo ""
echo "📁 Checking ArgoCD Manifests..."
ARGOCD_FILES=(
    "argocd/react-frontend-app.yaml"
    "argocd/flask-api-app.yaml"
)

for file in "${ARGOCD_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file - MISSING"
        ((ERRORS++))
    fi
done

echo ""
echo "📄 Checking Documentation..."
DOCS=(
    "COMPLETE_FRONTEND_GUIDE.md"
    "FRONTEND_DEPLOYMENT.md"
    "FRONTEND_QUICK_START.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC} $doc"
    else
        echo -e "${RED}✗${NC} $doc - MISSING"
        ((ERRORS++))
    fi
done

echo ""
echo "🐳 Checking Dockerfile..."
if [ -f "frontend_app/Dockerfile" ]; then
    echo -e "${GREEN}✓${NC} frontend_app/Dockerfile exists"

    # Check for correct port
    if grep -q "REACT_APP_API_URL=http://localhost:5000" frontend_app/Dockerfile; then
        echo -e "${GREEN}✓${NC} Dockerfile uses correct backend port (5000)"
    else
        echo -e "${RED}✗${NC} Dockerfile backend port might be incorrect"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗${NC} frontend_app/Dockerfile - MISSING"
    ((ERRORS++))
fi

echo ""
echo "✅ Checking Dependencies..."

# Check if docker is installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed: $(docker --version)"
else
    echo -e "${YELLOW}⚠${NC} Docker not found in PATH"
fi

# Check if kubectl is installed
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✓${NC} kubectl is installed: $(kubectl version --short 2>/dev/null | head -1)"
else
    echo -e "${YELLOW}⚠${NC} kubectl not found in PATH"
fi

# Check if helm is installed
if command -v helm &> /dev/null; then
    echo -e "${GREEN}✓${NC} Helm is installed: $(helm version --short)"
else
    echo -e "${YELLOW}⚠${NC} Helm not found in PATH"
fi

echo ""
echo "📦 Checking Helm Chart Validity..."
if helm lint frontend_app/helm/react-frontend/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Helm chart is valid"
else
    echo -e "${RED}✗${NC} Helm chart validation failed"
    ((ERRORS++))
fi

echo ""
echo "🔗 Checking Backend Connection Config..."
if grep -q "REACT_APP_API_URL.*flask-api.*5000" frontend_app/helm/react-frontend/values.yaml; then
    echo -e "${GREEN}✓${NC} Backend URL configured correctly"
else
    echo -e "${RED}✗${NC} Backend URL not configured correctly"
    ((ERRORS++))
fi

echo ""
echo "===================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for deployment${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Build Docker image: docker build -t ghcr.io/shreyaskn72/flask-react-frontend:latest ./frontend_app"
    echo "2. Push to GHCR: docker push ghcr.io/shreyaskn72/flask-react-frontend:latest"
    echo "3. Deploy: kubectl apply -f argocd/react-frontend-app.yaml"
    echo "4. Access: kubectl port-forward -n frontend-app svc/react-frontend 3000:80"
else
    echo -e "${RED}❌ $ERRORS issue(s) found${NC}"
    echo "Please fix the issues above before deploying"
fi

