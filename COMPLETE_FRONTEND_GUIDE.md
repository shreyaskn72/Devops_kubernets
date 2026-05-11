# Complete Frontend Kubernetes Deployment Guide

## 📋 Summary of What's Been Created

### Helm Chart (`frontend_app/helm/react-frontend/`)
```
Chart.yaml                    # Chart version & metadata
values.yaml                   # Configuration values
templates/
├── deployment.yaml          # Pod deployment spec
├── service.yaml             # Service exposure
├── ingress.yaml             # Ingress routing (optional)
├── helpers.tpl              # Template functions
└── NOTES.txt                # Post-install instructions
```

### ArgoCD Application
```
argocd/
├── flask-api-app.yaml       # Backend app (existing)
└── react-frontend-app.yaml  # Frontend app (NEW)
```

### Key Features
- ✅ Multi-replica deployment (2 replicas by default)
- ✅ Service discovery to Flask backend
- ✅ Health checks (liveness & readiness probes)
- ✅ Environment variable injection
- ✅ ArgoCD GitOps integration
- ✅ Ingress support (optional)

---

## 🚀 DEPLOYMENT WORKFLOW

### Phase 1: Build Docker Image

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets/frontend_app

# Build the image
docker build -t ghcr.io/shreyaskn72/flask-react-frontend:latest .

# Verify build (optional)
docker image ls | grep flask-react-frontend

# Tag with commit SHA (optional, for versioning)
docker tag ghcr.io/shreyaskn72/flask-react-frontend:latest \
  ghcr.io/shreyaskn72/flask-react-frontend:$(git rev-parse --short HEAD)
```

### Phase 2: Push to GHCR

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u shreyaskn72 --password-stdin

# Push latest tag
docker push ghcr.io/shreyaskn72/flask-react-frontend:latest

# Push commit SHA tag (optional)
docker push ghcr.io/shreyaskn72/flask-react-frontend:$(git rev-parse --short HEAD)

# Verify push
docker image inspect ghcr.io/shreyaskn72/flask-react-frontend:latest
```

### Phase 3: Deploy to Kubernetes

#### Option A: Using ArgoCD (RECOMMENDED)

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets

# Apply ArgoCD Application manifest
kubectl apply -f argocd/react-frontend-app.yaml

# Check status
kubectl get application -n argocd react-frontend

# Watch sync progress
kubectl get application -n argocd react-frontend -w

# Verify pods are running
kubectl get pods -n frontend-app
```

#### Option B: Using Helm Directly

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets

# Create namespace
kubectl create namespace frontend-app

# Install chart
helm install react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml

# Watch rollout
kubectl rollout status deployment/react-frontend -n frontend-app

# Verify
helm list -n frontend-app
kubectl get pods -n frontend-app
```

### Phase 4: Access the Application

```bash
# Port forward to localhost
kubectl port-forward -n frontend-app svc/react-frontend 3000:80

# Open in browser
open http://localhost:3000

# Or use curl
curl http://localhost:3000
```

---

## 📊 Configuration Guide

### Update Image Tag

Edit `frontend_app/helm/react-frontend/values.yaml`:

```yaml
image:
  repository: ghcr.io/shreyaskn72/flask-react-frontend
  tag: latest                    # Change this
  pullPolicy: Always
```

Then update:
```bash
# With ArgoCD (commit and push changes)
git add frontend_app/helm/react-frontend/values.yaml
git commit -m "chore: update frontend image tag"
git push origin master

# ArgoCD will auto-sync!

# Or manually with Helm
helm upgrade react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml
```

### Scaling Replicas

```yaml
# In values.yaml
replicaCount: 2    # Change to desired number
```

Apply changes:
```bash
helm upgrade react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml
```

### Enable Ingress

```yaml
# In values.yaml
ingress:
  enabled: true                    # Change to true
  className: "nginx"               # Set your ingress class
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # Optional
  hosts:
    - host: frontend.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: frontend-tls
      hosts:
        - frontend.example.com
```

---

## 🔍 Monitoring & Debugging

### Check Deployment Status

```bash
# Get pods
kubectl get pods -n frontend-app

# Get detailed pod info
kubectl describe pod -n frontend-app <pod-name>

# Get pod events
kubectl get events -n frontend-app --sort-by='.lastTimestamp'
```

### View Logs

```bash
# View logs from all frontend pods
kubectl logs -n frontend-app -l app=react-frontend -f

# View logs from specific pod
kubectl logs -n frontend-app <pod-name> -f

# View previous logs (if crashed)
kubectl logs -n frontend-app <pod-name> --previous
```

### Test Backend Connectivity

```bash
# Get pod name
POD=$(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}")

# Exec into pod
kubectl exec -it -n frontend-app $POD -- /bin/sh

# Inside pod, test backend:
wget http://flask-api:5000/
curl http://flask-api:5000/greeting?Name=Shreyas&City=Bangalore

# Check environment variables
env | grep REACT_APP_API_URL

# Exit pod
exit
```

### Check Service Discovery

```bash
# Test DNS from pod
POD=$(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}")

kubectl exec -it -n frontend-app $POD -- nslookup flask-api

# Should resolve to backend service IP
```

### Monitor with ArgoCD

```bash
# Access ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Open: https://localhost:8080
# Login with: admin / <password from: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d>

# View application status, sync status, and resource tree
```

---

## 🐛 Troubleshooting

### Pod stuck in ImagePullBackOff

```bash
# Check if image exists and is accessible
docker pull ghcr.io/shreyaskn72/flask-react-frontend:latest

# Check pod events
kubectl describe pod -n frontend-app <pod-name>

# Solution: Push image to GHCR
docker push ghcr.io/shreyaskn72/flask-react-frontend:latest
```

### Frontend can't reach backend

```bash
# Check backend service
kubectl get svc -n flask-app flask-api

# Check if backend pod is running
kubectl get pods -n flask-app

# Test connectivity from frontend pod
POD=$(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD -n frontend-app -- wget http://flask-api:5000/

# Check browser console for errors (F12 in browser)
```

### Service not accessible

```bash
# Get service details
kubectl get svc -n frontend-app

# Port forward
kubectl port-forward -n frontend-app svc/react-frontend 3000:80

# Test connectivity
curl http://localhost:3000
```

### Helm upgrade fails

```bash
# Check what will be deployed (dry-run)
helm upgrade react-frontend ./frontend_app/helm/react-frontend \
  -n frontend-app \
  --values ./frontend_app/helm/react-frontend/values.yaml \
  --dry-run --debug

# Rollback if needed
helm rollback react-frontend 0 -n frontend-app

# Get release history
helm history react-frontend -n frontend-app
```

---

## 📦 Helm Commands Reference

```bash
# Install
helm install react-frontend ./frontend_app/helm/react-frontend -n frontend-app

# Upgrade
helm upgrade react-frontend ./frontend_app/helm/react-frontend -n frontend-app

# Uninstall
helm uninstall react-frontend -n frontend-app

# Check values
helm values react-frontend -n frontend-app

# Test rendering (dry-run)
helm template react-frontend ./frontend_app/helm/react-frontend -n frontend-app

# Get release status
helm status react-frontend -n frontend-app

# List all releases
helm list -n frontend-app
```

---

## 🔄 CI/CD Integration

Your GitHub Actions workflow should:

1. ✅ Build Docker image on push
2. ✅ Push to GHCR with dynamic tag
3. ✅ Update Helm values.yaml
4. ✅ Commit changes
5. ✅ ArgoCD auto-syncs

Example workflow job (add to `.github/workflows/publish.yml`):

```yaml
      - name: Update Frontend Helm values
        run: |
          sed -i "s/tag: .*/tag: ${{ steps.version.outputs.tag }}/" \
            frontend_app/helm/react-frontend/values.yaml
          
      - name: Commit and push updated Helm values
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add frontend_app/helm/react-frontend/values.yaml
          git commit -m "chore: update frontend image tag to ${{ steps.version.outputs.tag }}" || exit 0
          git push
```

---

## ✅ Deployment Checklist

- [ ] Verified Dockerfile works locally (`docker build && docker run`)
- [ ] Built Docker image successfully
- [ ] Logged in to GHCR (`docker login ghcr.io`)
- [ ] Pushed image to GHCR (`docker push`)
- [ ] Verified image is accessible in GHCR
- [ ] Kubernetes cluster is running (`kubectl cluster-info`)
- [ ] Applied ArgoCD Application manifest (`kubectl apply -f argocd/react-frontend-app.yaml`)
- [ ] Frontend pods are running (`kubectl get pods -n frontend-app`)
- [ ] Frontend service is created (`kubectl get svc -n frontend-app`)
- [ ] Frontend can reach backend (tested with exec)
- [ ] Application accessible via port-forward
- [ ] All Helm templates validate (`helm template`)
- [ ] ArgoCD sync successful
- [ ] Environment variables set correctly

---

## 📞 Quick Commands

```bash
# Deploy
kubectl apply -f argocd/react-frontend-app.yaml

# Check status
kubectl get application -n argocd react-frontend

# Access
kubectl port-forward -n frontend-app svc/react-frontend 3000:80

# Logs
kubectl logs -n frontend-app -l app=react-frontend -f

# Debug pod
kubectl exec -it -n frontend-app $(kubectl get pods -n frontend-app -l app=react-frontend -o jsonpath="{.items[0].metadata.name}") -- /bin/sh

# Cleanup
kubectl delete namespace frontend-app
```

---

## 🎯 Next Steps

1. Build Docker image: `docker build -t ghcr.io/shreyaskn72/flask-react-frontend:latest .`
2. Push to GHCR: `docker push ghcr.io/shreyaskn72/flask-react-frontend:latest`
3. Deploy: `kubectl apply -f argocd/react-frontend-app.yaml`
4. Access: `kubectl port-forward -n frontend-app svc/react-frontend 3000:80`
5. Open: `http://localhost:3000`

Done! 🎉

