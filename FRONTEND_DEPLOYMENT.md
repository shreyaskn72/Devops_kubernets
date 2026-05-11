# Frontend Deployment Guide

Complete step-by-step guide to deploy the React frontend to Kubernetes using Helm and ArgoCD.

## Prerequisites

- Docker installed and running
- Kubernetes cluster (Docker Desktop or minikube)
- kubectl configured
- Helm 3+
- ArgoCD installed in your cluster

## Step 1: Build and Push Docker Image

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets/frontend_app

# Build the Docker image
docker build -t ghcr.io/shreyaskn72/flask-react-frontend:latest .

# Login to GHCR (GitHub Container Registry)
echo $GITHUB_TOKEN | docker login ghcr.io -u shreyaskn72 --password-stdin

# Push to GHCR
docker push ghcr.io/shreyaskn72/flask-react-frontend:latest
```

### Build with specific tag (commit SHA)

```bash
# Build with commit SHA
docker build -t ghcr.io/shreyaskn72/flask-react-frontend:$(git rev-parse --short HEAD) .
docker push ghcr.io/shreyaskn72/flask-react-frontend:$(git rev-parse --short HEAD)
```

---

## Step 2: Manual Helm Deployment (Optional)

If not using ArgoCD, deploy directly with Helm:

```bash
# Navigate to project root
cd /Users/shreyas/PycharmProjects/Devops_kubernets

# Create namespace
kubectl create namespace frontend-app

# Deploy using Helm
helm install react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml

# Verify deployment
kubectl get pods -n frontend-app
kubectl get svc -n frontend-app
```

### Update deployment (if image tag changed)

```bash
helm upgrade react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml \
  --set image.tag=master-abc123def
```

---

## Step 3: ArgoCD Deployment (Recommended)

### Deploy the ArgoCD Application

```bash
kubectl apply -f argocd/react-frontend-app.yaml
```

### Verify ArgoCD has synced

```bash
# Check ArgoCD application status
kubectl get application -n argocd react-frontend

# Watch ArgoCD sync
kubectl get application -n argocd react-frontend -w
```

### Access ArgoCD UI to monitor

```bash
# Port forward to ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Open browser: https://localhost:8080
# Default credentials: admin / (get password via: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
```

---

## Step 4: Access the Application

### Option A: Port Forward (Local Development)

```bash
# Port forward to frontend
kubectl port-forward -n frontend-app svc/react-frontend 3000:80

# Open browser: http://localhost:3000
```

### Option B: Enable Ingress (Production)

1. Update `frontend_app/helm/react-frontend/values.yaml`:

```yaml
ingress:
  enabled: true
  className: "nginx"  # or your ingress class
  hosts:
    - host: frontend.localhost
      paths:
        - path: /
          pathType: Prefix
```

2. Apply the update:

```bash
# If using ArgoCD, commit and push changes - ArgoCD will auto-sync
# Or manually update:
helm upgrade react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml
```

3. Access via: `http://frontend.localhost` (add to /etc/hosts if needed)

---

## Step 5: Verify Backend Connection

### Check if frontend can reach backend

```bash
# Get frontend pod
POD=$(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}")

# Test backend connectivity from pod
kubectl exec -it $POD -n frontend-app -- wget http://flask-api:5000/ -O -

# Check frontend logs
kubectl logs -n frontend-app $POD -f
```

### Verify environment variables

```bash
POD=$(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -n frontend-app -- env | grep REACT_APP_API_URL
```

---

## Troubleshooting

### Image Pull Issues

```bash
# Check if image exists
docker inspect ghcr.io/shreyaskn72/flask-react-frontend:latest

# Check pod events
kubectl describe pod -n frontend-app <pod-name>
```

### Frontend can't reach backend

1. Verify backend is running:
```bash
kubectl get pods -n flask-app
kubectl port-forward -n flask-app svc/flask-api 5000:80
curl http://localhost:5000/
```

2. Check DNS resolution in frontend pod:
```bash
POD=$(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -n frontend-app -- nslookup flask-api
```

### Deployment stuck in pending

```bash
# Check node resources
kubectl top nodes
kubectl top pods -n frontend-app

# Check events
kubectl get events -n frontend-app --sort-by='.lastTimestamp'
```

---

## Update Image Tag via GitHub Actions

Your CI/CD workflow should automatically:
1. Build Docker image on push
2. Push to GHCR with dynamic tag
3. Update `frontend_app/helm/react-frontend/values.yaml`
4. Commit changes to repo
5. ArgoCD automatically detects and syncs!

---

## Helm Chart Structure

```
frontend_app/helm/react-frontend/
├── Chart.yaml                 # Chart metadata
├── values.yaml                # Default values (customize here)
└── templates/
    ├── deployment.yaml        # Kubernetes Deployment
    ├── service.yaml           # Kubernetes Service
    ├── ingress.yaml           # Ingress (optional)
    ├── helpers.tpl            # Template helpers
    └── NOTES.txt              # Post-install notes
```

---

## Useful Commands

```bash
# Get deployment status
kubectl get deployment -n frontend-app -w

# Get pod details
kubectl describe pod -n frontend-app <pod-name>

# View container logs
kubectl logs -n frontend-app <pod-name> -f

# Execute command in pod
kubectl exec -it -n frontend-app <pod-name> -- /bin/sh

# Port forward
kubectl port-forward -n frontend-app svc/react-frontend 3000:80

# Delete deployment
helm uninstall react-frontend -n frontend-app

# Helm dry-run to see what will be deployed
helm install react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml \
  --dry-run --debug
```

---

## Production Checklist

- [ ] Docker image built and pushed to GHCR
- [ ] Image supports multi-platform (amd64, arm64)
- [ ] Backend API is running and accessible
- [ ] ArgoCD Application manifest created and applied
- [ ] Frontend can reach backend (verify in pod logs)
- [ ] Helm values.yaml configured correctly
- [ ] Namespace created (or auto-created by ArgoCD)
- [ ] Ingress configured (if needed)
- [ ] Pod health checks passing (liveness & readiness probes)
- [ ] Replica count set appropriately

---

## Environment Variables Reference

Frontend pod receives this environment variable at runtime:

```
REACT_APP_API_URL=http://flask-api:5000
```

This points to your Flask backend service.

