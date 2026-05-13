# Option 2: Local MySQL + Kubernetes (Docker Desktop) Setup Guide

## Overview

This setup runs:
- **MySQL 8.0** - Local Docker container on your machine (localhost:3306)
- **Flask API** - Deployed in Kubernetes (Docker Desktop)
- **Connection** - Using `host.docker.internal` to connect from K8s to local MySQL

---

## Prerequisites

✅ Docker Desktop installed with Kubernetes enabled
✅ kubectl configured
✅ Helm 3.x installed
✅ Flask API Docker image available

---

## Step-by-Step Setup

### Step 1: Start Local MySQL Container

```bash
docker run -d \
  --name local-mysql \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=flask_app \
  -e MYSQL_USER=flask_user \
  -e MYSQL_PASSWORD=flask_password \
  -p 3306:3306 \
  mysql:8.0
```

**What this does:**
- Starts MySQL container named `local-mysql`
- Creates database `flask_app`
- Creates user `flask_user` with password `flask_password`
- Exposes port 3306 on localhost

**Verify MySQL is running:**
```bash
docker logs local-mysql
docker exec local-mysql mysql -uflask_user -pflask_password flask_app -e "SELECT 1;"
```


For persistent storage (so DB survives container deletions), you can use a Docker volume:
```bash
docker volume create mysql_data
```

Then start MySQL with the volume:
```bash
docker run -d \
  --name local-mysql \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=flask_app \
  -e MYSQL_USER=flask_user \
  -e MYSQL_PASSWORD=flask_password \
  -p 3306:3306 \
  -v mysql_data:/var/lib/mysql \
  mysql:8.0
```



---

### Step 2: Check Your values.yaml Configuration

Your `values.yaml` should have:

```yaml
mysql:
  enabled: false  # Important! We're using local MySQL, not Helm's MySQL

env:
  - name: DB_HOST
    value: "host.docker.internal"  # Special DNS for Docker Desktop
  - name: DB_PORT
    value: "3306"
  - name: DB_USER
    value: flask_user
  - name: DB_PASSWORD
    value: "flask_password"  # Direct password (no secret needed for local dev)
  - name: DB_NAME
    value: flask_app
```

✅ Already updated! Ready to go!

---

### Step 3: Create Kubernetes Namespace

```bash
kubectl create namespace flask-app
```

Verify:
```bash
kubectl get namespace flask-app
```

---

### Step 4: Deploy Flask API with Helm

```bash
helm install flask-api ./flask_api/helm/flask-api \
  -n flask-app \
  -f ./flask_api/helm/flask-api/values.yaml
```

**Verify deployment:**
```bash
kubectl get pods -n flask-app
kubectl get svc -n flask-app
```

Wait for pods to be **Ready (1/1)**:
```bash
kubectl wait --for=condition=ready pod -l app=flask-api -n flask-app --timeout=300s
```

---

### Step 5: Check Logs (If Pod Fails)

```bash
# Get pod name
kubectl get pods -n flask-app

# View logs
kubectl logs <pod-name> -n flask-app -f
```

**Common errors:**
- `Connection refused` → MySQL not running
- `Unknown database` → Database not created
- `Access denied` → Wrong credentials

---

### Step 6: Port Forward to Access API

**Terminal 1 (Keep running):**
```bash
kubectl port-forward svc/flask-api 5000:80 -n flask-app
```

Now API is accessible at: `http://localhost:5000`

---

## Testing the Setup

### Test 1: Health Check
```bash
curl http://localhost:5000/health
```

Expected response:
```json
{"status": "healthy"}
```

### Test 2: Home Endpoint
```bash
curl http://localhost:5000/
```

Expected response:
```json
{"message": "Good morning from Shreyas K N! Welcome to CRUD API with MySQL"}
```

### Test 3: Create User
```bash
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "city": "New York",
    "age": 30
  }'
```

Expected response (201 Created):
```json
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "city": "New York",
    "age": 30,
    "created_at": "2026-05-13T10:30:45.123456",
    "updated_at": "2026-05-13T10:30:45.123456"
  }
}
```

### Test 4: Get All Users
```bash
curl http://localhost:5000/api/users
```

### Test 5: Run Full Test Suite
```bash
chmod +x test_crud_api.sh
./test_crud_api.sh
```

---

## Important: host.docker.internal Explanation

When Kubernetes pods in Docker Desktop need to access services on your host machine:

| Connection Type | How to Access |
|-----------------|---------------|
| **Pod → Local Service** | Use `host.docker.internal` |
| **Local → K8s Service** | Use `localhost:<port>` |
| **Pod → Another Pod** | Use service DNS name |

**Connection Flow in Option 2:**
```
Flask Pod in K8s
    ↓
Reads DB_HOST: host.docker.internal:3306
    ↓
Connects to MySQL on localhost
```

---

## Database Connection Details

From Flask Pod perspective:
```
mysql+pymysql://flask_user:flask_password@host.docker.internal:3306/flask_app
```

From your machine perspective:
```
mysql+pymysql://flask_user:flask_password@localhost:3306/flask_app
```

---

## Troubleshooting

### Issue 1: Pod Can't Connect to MySQL

**Check logs:**
```bash
kubectl logs <pod-name> -n flask-app
```

**Look for error:**
```
Error connecting to MySQL at host.docker.internal:3306
```

**Solution:**
1. Verify MySQL is running: `docker ps | grep local-mysql`
2. Test local connection: `mysql -h localhost -uflask_user -pflask_password`
3. Restart MySQL: `docker restart local-mysql`

### Issue 2: Port Already in Use

```bash
# Kill process using port 3306
lsof -ti:3306 | xargs kill -9

# Or start MySQL on different port
docker run -d --name local-mysql -p 3307:3306 ...
```

### Issue 3: Can't Connect from Postman

Use: `http://localhost:5000`

Not: `http://host.docker.internal:5000`

---

## Managing the Setup

### View All Resources
```bash
kubectl get all -n flask-app
```

### View Pod Logs
```bash
kubectl logs -f deployment/flask-api -n flask-app
```

### Scale Replicas
```bash
kubectl scale deployment flask-api --replicas=3 -n flask-app
```

### Get Into Pod (Debug)
```bash
kubectl exec -it <pod-name> -n flask-app /bin/bash
```

### Check MySQL Data
```bash
docker exec local-mysql mysql -uflask_user -pflask_password flask_app -e "SELECT * FROM users;"
```

---

## Cleanup

### Stop Everything

```bash
# Delete Kubernetes deployment
helm uninstall flask-api -n flask-app

# Delete namespace
kubectl delete namespace flask-app

# Stop MySQL container
docker stop local-mysql

# Remove MySQL container
docker rm local-mysql
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start MySQL | `docker run -d --name local-mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=rootpassword -e MYSQL_DATABASE=flask_app -e MYSQL_USER=flask_user -e MYSQL_PASSWORD=flask_password mysql:8.0` |
| Check MySQL | `docker logs local-mysql` |
| Deploy API | `helm install flask-api ./flask_api/helm/flask-api -n flask-app` |
| Port Forward | `kubectl port-forward svc/flask-api 5000:80 -n flask-app` |
| View Logs | `kubectl logs -f deployment/flask-api -n flask-app` |
| Test API | `curl http://localhost:5000/health` |
| Cleanup | `helm uninstall flask-api -n flask-app && docker stop local-mysql` |

---

## Alternative: Use the Deployment Script

Instead of manual steps, run:

```bash
chmod +x deploy-option2-local-mysql.sh
./deploy-option2-local-mysql.sh
```

This script automates all steps 1-7!

---

## Next Steps

1. ✅ Start MySQL
2. ✅ Deploy with Helm
3. ✅ Port forward
4. ✅ Test endpoints
5. ✅ Verify data in MySQL

**You're all set for local development on Docker Desktop!** 🚀

---

**MySQL Credentials (Keep Safe for Production):**
- User: `flask_user`
- Password: `flask_password`
- Database: `flask_app`

**⚠️ Note:** These are development credentials. Never use these in production!

