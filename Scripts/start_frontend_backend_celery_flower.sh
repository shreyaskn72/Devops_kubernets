set -e

echo "Creating backend..."

kubectl apply -f ../argocd/flask-api-app.yaml

echo "Waiting for flask-app pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n flask-app --timeout=300s

echo ""
echo "flask-app deployment complete."
echo ""


echo "Creating frontend react-frontend-app..."

kubectl apply -f ../argocd/react-frontend-app.yaml

echo "Waiting for react-frontend-app pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n frontend-app --timeout=300s

echo ""
echo "frontend react-frontend-app complete."
echo ""


echo "Creating celery-worker..."

kubectl apply -f ../argocd/celery-worker.yaml

echo "Waiting for celery-worker pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n celery-worker --timeout=300s

echo ""
echo "celery-worker complete."
echo ""


echo "Creating celery-beat..."

kubectl apply -f ../argocd/celery-beat.yaml

echo "Waiting for celery-beat pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n celery-beat --timeout=300s

echo ""
echo "celery-beat complete."
echo ""


echo "Creating flower..."

kubectl apply -f ../argocd/flower.yaml

echo "Waiting for flower pods to become ready..."

kubectl wait --for=condition=Ready pods --all -n flower --timeout=300s

echo ""
echo "flower complete."
echo ""