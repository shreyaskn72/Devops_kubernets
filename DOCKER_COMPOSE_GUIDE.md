# Docker Compose Setup Guide

This Docker Compose configuration mirrors your Kubernetes Helm setup, allowing you to run the entire stack locally.

## Services Included

| Service | Port | Purpose |
|---------|------|---------|
| **RabbitMQ** | 5672, 15672 | Message broker for Celery |
| **Redis** | 6379 | Result backend & caching |
| **MySQL** | 3306 | Database |
| **Flask API** | 5000 | Backend API |
| **React Frontend** | 3000 | Web UI |
| **Celery Worker** | - | Task processing |
| **Celery Beat** | - | Scheduled tasks |
| **Flower** | 5555 | Celery monitoring |

## Prerequisites

- Docker & Docker Compose installed
- Sufficient disk space for volumes

## Quick Start

### 1. Start all services
```bash
cd /Users/shreyas/PycharmProjects/Devops_kubernets_demo
docker-compose up -d
```

### 2. Check service status
```bash
docker-compose ps
```

### 3. View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f flask-api
docker-compose logs -f celery-worker
```

### 4. Access services
- **Frontend**: http://localhost:3000
- **Flask API**: http://localhost:5000
- **RabbitMQ Admin**: http://localhost:15672 (rabbituser/rabbitpass)
- **Flower (Celery Monitor)**: http://localhost:5555

## Database Credentials

```
MySQL:
  Host: localhost
  Port: 3306
  User: flask_user
  Password: flask_password
  Database: flask_app
  Root Password: rootpassword

RabbitMQ:
  User: rabbituser
  Password: rabbitpass
```

## Common Commands

### Stop all services
```bash
docker-compose down
```

### Stop and remove volumes
```bash
docker-compose down -v
```

### Restart a service
```bash
docker-compose restart flask-api
```

### Rebuild images
```bash
docker-compose up -d --build
```

### Execute command in service
```bash
docker-compose exec flask-api python manage.py migrate
docker-compose exec mysql mysql -u flask_user -pflask_password flask_app
```

### View service logs
```bash
docker-compose logs -f celery-worker --tail=50
```

## Troubleshooting

### Services won't start
```bash
# Check for port conflicts
lsof -i :5000
lsof -i :3000
lsof -i :5672

# Force remove containers
docker-compose down
docker system prune -a
docker-compose up -d
```

### Database connection issues
```bash
# Verify MySQL is healthy
docker-compose exec mysql mysqladmin ping -h localhost -u flask_user -pflask_password

# Check database exists
docker-compose exec mysql mysql -u flask_user -pflask_password -e "SHOW DATABASES;"
```

### Celery Worker not processing tasks
```bash
# Check RabbitMQ connection
docker-compose logs celery-worker

# Check Redis connection
docker-compose exec redis redis-cli ping

# Verify Celery can connect to broker
docker-compose exec celery-worker celery -A app.celery inspect active
```

### Memory/Resource issues
```bash
# Check resource usage
docker stats

# Reduce replicas or resource limits in compose file if needed
```

## Performance Tuning

Edit `docker-compose.yml` for production:

1. **Increase Celery Worker Concurrency**
   ```yaml
   celery-worker:
     command: celery -A app.celery worker --loglevel=info --concurrency=4
   ```

2. **Add more Flask replicas** (requires load balancer):
   ```yaml
   flask-api-1:
     ...
   flask-api-2:
     ...
   ```

3. **Redis Persistence** (already enabled):
   ```yaml
   redis:
     command: redis-server --appendonly yes --save 60 1000
   ```

## Comparison: Kubernetes vs Docker Compose

| Aspect | Kubernetes | Docker Compose |
|--------|-----------|-----------------|
| Scaling | Horizontal (multiple replicas) | Single instance per service |
| Service Discovery | K8s DNS | Docker network |
| Load Balancing | Ingress/Service | Manual with reverse proxy |
| Persistence | PersistentVolumes | Docker volumes |
| Networking | Complex policies | Simple bridge network |
| Production Ready | Yes | Development/Testing |

For production, use Kubernetes. For local development and testing, use Docker Compose.
