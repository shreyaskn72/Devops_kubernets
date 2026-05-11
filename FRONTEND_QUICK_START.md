# Quick Start: Frontend Deployment Summary

## Files Created

✅ **Helm Chart** (frontend_app/helm/react-frontend/)
- `Chart.yaml` - Chart metadata
- `values.yaml` - Configuration (image, replicas, etc.)
- `templates/deployment.yaml` - Kubernetes Deployment
- `templates/service.yaml` - Kubernetes Service
- `templates/ingress.yaml` - Ingress configuration
- `templates/helpers.tpl` - Template helpers
- `templates/NOTES.txt` - Post-deployment notes

✅ **ArgoCD Application** (argocd/)
- `react-frontend-app.yaml` - ArgoCD Application manifest

✅ **Updated Files**
- `frontend_app/Dockerfile` - Verified & uses correct backend port (5000)

---

## Quick Deployment Steps

### 1️⃣ Build & Push Docker Image

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets/frontend_app
docker build -t ghcr.io/shreyaskn72/flask-react-frontend:latest .
docker login ghcr.io
docker push ghcr.io/shreyaskn72/flask-react-frontend:latest
```

### 2️⃣ Deploy with ArgoCD (Recommended)

```bash
# From project root
kubectl apply -f argocd/react-frontend-app.yaml
```

### 3️⃣ Access the Application

```bash
# Port forward
kubectl port-forward -n frontend-app svc/react-frontend 3000:80

# Open: http://localhost:3000
```

---

## Key Configuration

**Backend API URL (set automatically):**
```
REACT_APP_API_URL=http://flask-api:5000
```

This allows the frontend pod to communicate with the backend Flask API service within the cluster.

---

## Verify Deployment

```bash
# Check pods
kubectl get pods -n frontend-app

# Check service
kubectl get svc -n frontend-app

# Check ArgoCD status
kubectl get application -n argocd react-frontend

# View logs
kubectl logs -n frontend-app -l app=react-frontend -f
```

---

## Architecture

```
┌─────────────────────┐
│   Browser (3000)    │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  React Frontend     │
│  (frontend-app)     │
└──────────┬──────────┘
           │
           │ http://flask-api:5000
           │
┌──────────▼──────────┐
│  Flask Backend      │
│  (flask-api)        │
└─────────────────────┘
```

---

## File Structure

```
frontend_app/
├── helm/react-frontend/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── helpers.tpl
│       └── NOTES.txt
├── Dockerfile
├── public/
├── src/
└── package.json

argocd/
├── flask-api-app.yaml
└── react-frontend-app.yaml    ← New!
```

---

## Next Steps

1. ✅ Build Docker image
2. ✅ Push to GHCR
3. ✅ Apply ArgoCD manifest
4. ✅ Monitor with ArgoCD UI
5. ✅ Access frontend via port-forward

For detailed instructions, see: `FRONTEND_DEPLOYMENT.md`

