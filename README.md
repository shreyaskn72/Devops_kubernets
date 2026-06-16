
# Kubernetes Flask + Celery Platform

Production-style Flask + Celery application deployed on Kubernetes using:

- Flask API
- React Frontend
- Celery Worker
- Celery Beat
- Flower
- RabbitMQ
- Redis
- Helm
- ArgoCD
- GitHub Actions

---

# Architecture Overview

```text
React Frontend
       ↓
Flask API
       ↓
RabbitMQ / Redis
       ↓
Celery Workers
       ↓
MySQL


---

# Repository Structure

```text
project/
├── argocd/
├── flask_api/
├── frontend/
├── helm/
│   ├── flask-api/
│   ├── celery-worker/
│   ├── celery-beat/
│   ├── flower/
│   ├── values-rabbitmq.yaml
│   └── values-redis.yaml
```

---

# Namespaces Used

| Namespace     | Purpose           |
|---------------|-------------------|
| argocd        | ArgoCD GitOps     |
| flask-app     | Flask backend     |
| frontend-app  | React frontend    |
| messaging     | RabbitMQ          |
| cache         | Redis             |
| flower        | Flower monitoring |
| celery-worker | celery-worker     |
| celery-beat   | celery-beat       |

---

# Prerequisites

Ensure the following are installed locally:

* Docker Desktop
* Kubernetes enabled in Docker Desktop
* kubectl
* Helm
* Git

---

# Install ArgoCD

## Create Namespace

```bash
kubectl create namespace argocd
```

---

## Install ArgoCD

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## Verify Pods

```bash
kubectl get pods -n argocd
```

All pods should be in `Running` state.

---

## Access ArgoCD UI

Port forward the ArgoCD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open in browser:

```text
http://localhost:8080
```

---

## Retrieve Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

### Login Credentials

```text
Username: admin
Password: <output-from-command>
```

---

# Deploy Flask API Through ArgoCD

## Navigate to ArgoCD Manifests

```bash
cd argocd
```

---

## Apply Flask API Application

```bash
kubectl apply -f flask-api-app.yaml
```

---

## Verify Service

```bash
kubectl get svc -n flask-app
```

Example:

```text
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
flask-api-flask-api   ClusterIP   10.107.228.211   <none>        80/TCP
```

---

## Port Forward Flask API

> NOTE:
> Kubernetes Service Port and Container Port are different.

```text
Service Port    →    Container Port
80              →    5000
```

Port forward:

```bash
kubectl port-forward svc/flask-api-flask-api 5000:80 -n flask-app
```

Access API:

```text
http://localhost:5000
```

---

# Deploy React Frontend Through ArgoCD

## Apply Frontend Application

```bash
kubectl apply -f react-frontend-app.yaml
```

---

## Verify Frontend Service

```bash
kubectl get svc -n frontend-app
```

Example:

```text
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
react-frontend   ClusterIP   10.106.45.34   <none>        80/TCP
```

---

## Port Forward React Frontend

```text
Service Port    →    Container Port
80              →    3000
```

Port forward:

```bash
kubectl port-forward svc/react-frontend 3000:80 -n frontend-app
```

Access frontend:

```text
http://localhost:3000
```

---

# Local MySQL Setup (Development Only)

## Start MySQL Container

## Persistent MySQL Storage (Create only first time, ignore if done)

Create Docker volume:

```bash
docker volume create mysql_data
```

## Run MySQL with persistence:

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

Additional details:

[LOCAL_MYSQL_GUIDE.md](./LOCAL_MYSQL_GUIDE.md)

---

# RabbitMQ Setup

## Create Namespace

```bash
kubectl create namespace messaging
```

---

## Navigate to Helm Directory

```bash
cd helm
```

---

## Apply RabbitMQ Configuration

```bash
kubectl apply -f values-rabbitmq.yaml
```

---

## Verify RabbitMQ Pods

```bash
kubectl get pods -n messaging -w
```

Expected:

```text
rabbitmq-xxxxx   1/1 Running
```

---

## Verify RabbitMQ Service

```bash
kubectl get svc -n messaging
```

Expected:

```text
rabbitmq   ClusterIP   xxx.xxx.xxx.xxx   5672/TCP,15672/TCP
```

---

## Access RabbitMQ UI

Port forward:

```bash
kubectl port-forward svc/rabbitmq 15672:15672 -n messaging
```

Open:

```text
http://localhost:15672
```

Login:

```text
Username: rabbituser
Password: rabbitpass
```

---

## RabbitMQ Connection String (Inside Kubernetes)

```text
amqp://rabbituser:rabbitpass@rabbitmq.messaging.svc.cluster.local:5672//
```

---

## RabbitMQ Connection String (Local Development)

Port forward:

```bash
kubectl port-forward svc/rabbitmq 5672:5672 -n messaging
```

Connection string:

```text
amqp://rabbituser:rabbitpass@localhost:5672//
```

---

# Redis Setup

## Create Namespace

```bash
kubectl create namespace cache
```

---

## Add Bitnami Helm Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update
```

---

## Install Redis

```bash
helm install redis bitnami/redis \
  -n cache \
  -f values-redis.yaml
```

---

## Verify Redis Pods

```bash
kubectl get pods -n cache
```

Expected:

```text
redis-master-0   1/1 Running
```

---

## Verify Persistent Volume Claims

```bash
kubectl get pvc -n cache
```

Expected:

```text
STATUS: Bound
```

---

## Verify Redis Services

```bash
kubectl get svc -n cache
```

Expected:

```text
redis-master
redis-headless
```

---

## Test Redis

```bash
kubectl exec -it redis-master-0 -n cache -- redis-cli
```

Inside Redis CLI:

```bash
PING
```

Expected:

```text
PONG
```

Exit Redis CLI:

```bash
exit
```

---

## Redis Connection String (Inside Kubernetes)

```text
redis://redis-master.cache.svc.cluster.local:6379/0
```

---

## Redis Connection String (Local Development)

Port forward:

```bash
kubectl port-forward svc/redis-master 6379:6379 -n cache
```

Connection string:

```text
redis://localhost:6379/0
```

---

# Deploy Celery Components Through ArgoCD

## Navigate to ArgoCD Directory

```bash
cd argocd
```

---

## Deploy Celery Worker

```bash
kubectl apply -f celery-worker.yaml
```

> NOTE:
> Celery Worker runs internally and does not require port forwarding.

---

## Deploy Celery Beat

```bash
kubectl apply -f celery-beat.yaml
```

---

## Deploy Flower

```bash
kubectl apply -f flower.yaml
```

---

## Access Flower UI

Port forward:

```bash
kubectl port-forward svc/flower-service 5555:5555 -n flower
```

Open:

```text
http://localhost:5555
```

---

# Local Development Commands

## Run Celery Worker Locally

```bash
celery -A celery_app worker --loglevel=info
```

---

## Run Flower Locally

```bash
celery -A celery_app flower
```

---

# Useful Kubernetes Commands

## View All Pods

```bash
kubectl get pods --all-namespaces
```

---

## View Logs

```bash
kubectl logs <pod-name> -n <namespace>
```

---

## Restart Deployment

```bash
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

---

## Check Services

```bash
kubectl get svc -A
```

---

## Check ArgoCD Applications

```bash
kubectl get applications -n argocd
```

---

# Production Improvements

Future improvements for AKS production deployments:

* Ingress Controller
* HTTPS / TLS
* Azure Key Vault
* HPA Autoscaling
* Prometheus + Grafana
* StatefulSets
* Persistent Volumes
* Azure Database for MySQL/PostgreSQL
* Azure Cache for Redis
* RabbitMQ Clustering
* Network Policies
* OpenTelemetry
* CI/CD Security Scanning

---

# Additional Documentation

* [helm_runbook.md](./helm_runbook.md)
* [LOCAL_MYSQL_GUIDE.md](./LOCAL_MYSQL_GUIDE.md)

```
```
