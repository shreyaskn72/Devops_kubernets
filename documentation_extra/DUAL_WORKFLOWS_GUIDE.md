# GitHub Actions Workflows Documentation

## Overview

You now have **two independent workflows** for managing backend and frontend deployments:

1. **`publish.yml`** - Backend (Flask API) workflow
2. **`publish-frontend.yml`** - Frontend (React) workflow

Each workflow is completely independent and only triggers when its respective code changes.

---

## Workflow Architecture

```
┌─────────────────────────────────────────────────────┐
│          Developer Push to Master                   │
│          git push origin master                     │
└──────────────┬────────────────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
    ┌─────────┐   ┌───────────┐
    │Backend  │   │Frontend   │
    │Changed? │   │Changed?   │
    └────┬────┘   └─────┬─────┘
         │              │
         ▼              ▼
    Trigger        Trigger
    publish.yml    publish-frontend.yml
         │              │
         ▼              ▼
    Build & Push   Build & Push
    Backend Image  Frontend Image
         │              │
         ▼              ▼
    Update         Update
    Backend Helm   Frontend Helm
         │              │
         └──────┬───────┘
                ▼
         ArgoCD Detects Changes
         Auto-Syncs Both Apps
                ▼
         ✅ Both Services Updated
```

---

## Workflow 1: Backend (publish.yml)

### Triggers

```yaml
on:
  push:
    branches:
      - master        # Runs on master push
    tags:
      - 'v*'          # Runs on version tags
    paths-ignore:
      - 'frontend_app/**'   # IGNORED: Frontend changes
```

**Runs when:**
- ✅ Changes to `flask_api/` directory
- ✅ Changes to `flask_api/helm/`
- ✅ Git tag pushed (v1.0.0, etc.)

**Does NOT run when:**
- ❌ Only `frontend_app/` changes
- ❌ Only documentation changes

### Steps

1. **Checkout code**
2. **Login to GHCR**
3. **Setup Docker Buildx** (multi-platform)
4. **Generate image tag** (master-abc123 or v1.0.0)
5. **Build & push** backend Docker image
6. **Update** `flask_api/helm/flask-api/values.yaml`
7. **Auto-commit & push** changes

### Example: Backend Push

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets/flask_api
echo "print('hello world')" >> app.py
git add app.py
git commit -m "Add logging"
git push origin master
```

**Result:**
- ✅ Backend image built: `hello-world-flask-kubernets:master-abc123`
- ✅ Backend Helm values updated
- ✅ `flask_api/helm/flask-api/values.yaml` committed
- ✅ ArgoCD auto-syncs backend only
- ❌ Frontend NOT affected

---

## Workflow 2: Frontend (publish-frontend.yml)

### Triggers

```yaml
on:
  push:
    branches:
      - master        # Runs on master push
    tags:
      - 'v*'          # Runs on version tags
    paths:
      - 'frontend_app/**'              # ONLY: Frontend changes
      - '.github/workflows/publish-frontend.yml'
```

**Runs when:**
- ✅ Changes to `frontend_app/` directory
- ✅ Changes to `frontend_app/helm/`
- ✅ Git tag pushed (v1.0.0, etc.)

**Does NOT run when:**
- ❌ Only `flask_api/` changes
- ❌ Only `argocd/` changes
- ❌ Only documentation changes

### Steps

1. **Checkout code**
2. **Login to GHCR**
3. **Setup Docker Buildx** (multi-platform)
4. **Generate image tag** (master-xyz789 or v1.0.0)
5. **Build & push** frontend Docker image
6. **Update** `frontend_app/helm/react-frontend/values.yaml`
7. **Auto-commit & push** changes

### Example: Frontend Push

```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets/frontend_app/src
echo "// New comment" >> App.js
git add .
git commit -m "Update frontend UI"
git push origin master
```

**Result:**
- ✅ Frontend image built: `flask-react-frontend:master-xyz789`
- ✅ Frontend Helm values updated
- ✅ `frontend_app/helm/react-frontend/values.yaml` committed
- ✅ ArgoCD auto-syncs frontend only
- ❌ Backend NOT affected

---

## Complete GitOps Flow

### Scenario 1: Backend Only Change

```bash
# Change backend code
echo "# comment" >> flask_api/app.py
git add flask_api/app.py
git commit -m "Backend fix"
git push origin master
```

**Execution:**
1. `publish.yml` triggered ✅
2. `publish-frontend.yml` skipped ❌
3. Backend image built & pushed
4. Backend Helm updated
5. ArgoCD: Backend synced, Frontend untouched

---

### Scenario 2: Frontend Only Change

```bash
# Change frontend code
echo "// comment" >> frontend_app/src/App.js
git add frontend_app/src/App.js
git commit -m "Frontend fix"
git push origin master
```

**Execution:**
1. `publish.yml` skipped ❌
2. `publish-frontend.yml` triggered ✅
3. Frontend image built & pushed
4. Frontend Helm updated
5. ArgoCD: Frontend synced, Backend untouched

---

### Scenario 3: Release Tag

```bash
# Create release tag
git tag v1.2.0
git push origin v1.2.0
```

**Execution:**
1. `publish.yml` triggered ✅ (because of 'v*' tag)
2. `publish-frontend.yml` triggered ✅ (because of 'v*' tag)
3. Both images built with tag `v1.2.0`
4. Both Helm values updated to `v1.2.0`
5. ArgoCD: Both services synced with v1.2.0

---

### Scenario 4: Both Changes (Feature Branch)

```bash
# Update both
echo "# backend" >> flask_api/app.py
echo "// frontend" >> frontend_app/src/App.js
git add .
git commit -m "Feature: new API and UI"
git push origin master
```

**Execution:**
1. `publish.yml` triggered ✅
2. `publish-frontend.yml` triggered ✅
3. Both images built with same tag (master-abc123)
4. Both Helm values updated
5. ArgoCD: Both services synced together

---

## Files Modified by Each Workflow

### publish.yml modifies:
```
✅ flask_api/helm/flask-api/values.yaml
   └─ Updates: image.tag
```

### publish-frontend.yml modifies:
```
✅ frontend_app/helm/react-frontend/values.yaml
   └─ Updates: image.tag
```

### Neither workflow modifies:
```
❌ ArgoCD manifests
❌ Helm Chart.yaml
❌ Helm templates
❌ Application code
```

---

## Docker Images Generated

### Backend Images
```
ghcr.io/shreyaskn72/hello-world-flask-kubernets:master-abc123
ghcr.io/shreyaskn72/hello-world-flask-kubernets:latest
ghcr.io/shreyaskn72/hello-world-flask-kubernets:v1.0.0 (on tag)
```

### Frontend Images
```
ghcr.io/shreyaskn72/flask-react-frontend:master-xyz789
ghcr.io/shreyaskn72/flask-react-frontend:latest
ghcr.io/shreyaskn72/flask-react-frontend:v1.0.0 (on tag)
```

Both support `linux/amd64` and `linux/arm64` architectures.

---

## Workflow Isolation Benefits

### ✅ Independent Deployments
- Backend can be updated without affecting frontend
- Frontend can be updated without affecting backend
- Faster CI/CD for smaller changes

### ✅ Cleaner History
- Each workflow has its own commits
- Easy to track which service was updated
- Separate git history for analysis

### ✅ Reduced Risk
- Changes to frontend code won't break backend build
- Changes to backend code won't break frontend build
- Easier rollback if one service has issues

### ✅ Resource Optimization
- Only changed service builds Docker image
- Only changed service's Helm values update
- Reduces unnecessary workflows

---

## Monitoring Workflows

### In GitHub UI

1. Go to: **Your Repo → Actions**
2. See both workflows:
   - "Build and Push to GHCR" (backend)
   - "Build and Push Frontend to GHCR" (frontend)
3. Click on workflow to see details
4. View step-by-step execution and logs

### View Recent Runs

```bash
# Check which workflows ran recently
cd /Users/shreyas/PycharmProjects/Devops_kubernets
git log --oneline -10

# Look for:
# - "chore: update image tag to master-xxx" (backend)
# - "chore: update frontend image tag to master-xxx" (frontend)
```

---

## Troubleshooting

### Frontend Workflow Not Running?

Check if path changed:
```bash
# Verify you modified frontend_app/
git diff HEAD~1 --name-only | grep frontend_app

# If no output, workflow won't trigger
# Add a change to frontend_app/ to trigger
```

### Backend Workflow Not Running?

Check if path changed:
```bash
# Verify you modified flask_api/
git diff HEAD~1 --name-only | grep flask_api

# If no output, workflow won't trigger
```

### Manual Trigger

To manually trigger a workflow:
1. Go to GitHub Actions
2. Select workflow
3. Click "Run workflow"
4. Choose branch
5. Click green "Run workflow" button

### Check Workflow Logs

```bash
# View GHCR push logs
curl https://ghcr.io/v2/shreyaskn72/flask-react-frontend/tags/list \
  -H "Authorization: Bearer $GITHUB_TOKEN"

# View git commits
git log --oneline | head -5
```

---

## Performance Expectations

| Task | Time |
|------|------|
| Build Backend | ~2-3 min |
| Push Backend | ~1 min |
| Build Frontend | ~2-3 min |
| Push Frontend | ~1 min |
| Git commit | ~10 sec |
| ArgoCD sync | ~10-30 sec |
| **Total (one service)** | **~5-7 min** |
| **Total (both)** | **~7-9 min** (parallel) |

---

## Complete GitOps Pipeline

```
Developer Code Change
        ↓
git push origin master
        ↓
GitHub Detects Push
        ↓
╔══════════════════════════════════╗
║   Check Which Files Changed      ║
╚══════════════════════════════════╝
        ↓
    ┌───┴───┐
    │       │
┌───▼──┐  ┌─▼────┐
│Backend│  │Frontend│
│Changed │  │Changed │
└───┬──┘  └──┬───┘
    │        │
    ▼        ▼
trigger  trigger
pub.yml  pub-front.yml
    │        │
    ├─────┬──┤
    │     │  │
    ▼     ▼  ▼
 Build   Build
 Image   Image
    │     │
    └──┬──┘
       ▼
    Push to GHCR
       ▼
 Update Helm Values
       ▼
   Auto-commit
       ▼
   Push to Git
       ▼
 ArgoCD Detects
       ▼
  Auto-Sync
       ▼
  Kubernetes
   Updated
       ▼
    ✅ Done!
```

---

## Workflow Files Location

```
.github/workflows/
├── publish.yml              ← Backend workflow
└── publish-frontend.yml     ← Frontend workflow (NEW)
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Backend Workflow** | `publish.yml` |
| **Frontend Workflow** | `publish-frontend.yml` |
| **Trigger** | Push to master or git tag |
| **Path Isolation** | Backend & Frontend isolated |
| **Auto Updates** | Helm values + git commit |
| **Auto Deploy** | ArgoCD syncs automatically |
| **Status** | ✅ READY |

---

## Next Steps

1. ✅ Workflows created
2. ✅ Independent configurations
3. ✅ Path-based triggers active
4. Push changes to trigger workflows!

**Status: TWO INDEPENDENT WORKFLOWS READY** 🚀

