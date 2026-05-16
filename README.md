## Install argocd
```bash
kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```  

### check argocd pods
```bash
kubectl get pods -n argocd
```
All pods should be in `Running` state.




### Access the ArgoCD UI

port forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then open in your browser:
👉 **[http://localhost:8080](http://localhost:8080)**


Get admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Username
```
admin
```

### Deploy Local Helm Chart Through ArgoCD


From repo's root directory.. Go inside `/argocd` folder by using 
```bash
cd argocd
```
Apply the ArgoCD application manifest:
```bash
kubectl apply -f flask-api-app.yaml
```



### Port forward to access the Flask API

Check the actual service ports first:
```bash
kubectl get svc -n flask-app
```
You will see something like this:
```
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
flask-api-flask-api   ClusterIP   10.107.228.211   <none>        80/TCP    2m37s
```

In kubernetes
```bash
Service Port  -> Container Port
80            -> 5000
```
So your container listens on 5000, but the Service exposes 80.

That means your port-forward should be:

```bash
kubectl port-forward svc/flask-api-flask-api 5000:80 -n flask-app
```

Then open in your browser:
👉 **[http://localhost:5000](http://localhost:5000)**



If you want to manually handle helm check this [helm_runbook.md](./helm_runbook.md)


## Start mysql db locally in docker for desktop for development purpose

```bash
# Using Docker
docker run --name local-mysql \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=flask_app \
  -e MYSQL_USER=flask_user \
  -e MYSQL_PASSWORD=flask_password \
  -p 3306:3306 \
  mysql:8.0
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

For more information check this [LOCAL_MYSQL_GUIDE.md](./LOCAL_MYSQL_GUIDE.md)


Similarly for frontend use the commands

Inside argocd folder

```bash
kubectl apply -f react-frontend-app.yaml
```

### Port forward to access the React Frontend
Check the actual service ports first:
```bash
kubectl get svc -n frontend-app
```

You will see something like this:
```
NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
react-frontend   ClusterIP   10.106.45.34   <none>        80/TCP    4m
```
In kubernetes
```bash
Service Port  -> Container Port
80            -> 3000
```

So your port-forward should be:

```bash
kubectl port-forward svc/react-frontend 3000:80 -n frontend-app
```

Then open in your browser:
👉 **[http://localhost:3000](http://localhost:3000)**


# For configuring rabbitmq manually use the instructions below:


## STEP 1 — Create namespace called messaging

```bash
kubectl create ns messaging
```

---

## STEP 2 — apply values-rabbitmq.yaml

From root directory go inside helm folder
```bash
cd helm
```
Then apply values in values-rabbitmq.yaml
```bash
kubectl apply -f values-rabbitmq.yaml
```
---

## STEP 3 — Verify if pods are running

```bash
kubectl get pods -n messaging -w
```

It should show something like this
```bash
NAME                       READY   STATUS    RESTARTS   AGE
rabbitmq-5fdf77b4d-tkd64   1/1     Running   0          9s
```

Observe status should be in Running state
---

## STEP 4: Check the por tof service
```bash
kubectl get svc -n messaging
```

It should show something like this:
```bash
NAME       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)              AGE
rabbitmq   ClusterIP   10.109.217.252   <none>        5672/TCP,15672/TCP   73s
```
Note down the port

## STEP 5 — Access Rabbitmq UI

```bash id
kubectl port-forward svc/rabbitmq 15672:15672 -n messaging
```

Open:

```text id="jlwm0i"
http://localhost:15672
```

Login:

```text id="jlwm1j"
rabbituser
rabbitpass
```

## Rabbitmq Inside Kubernetes

Use this connection string from your Flask/Celery apps:
```
amqp://rabbituser:rabbitpass@rabbitmq.messaging.svc.cluster.local:5672//
```

## For local running of api and flask-app

First port forward:
```
kubectl port-forward svc/rabbitmq 5672:5672 -n messaging
```
Then Use Connection String:
```
broker="amqp://rabbituser:rabbitpass@localhost:5672//"
```


---


## In production You Can Upgrade To

* StatefulSet
* persistence
* HA queues
* RabbitMQ clustering
* operators
* Bitnami chart
* RabbitMQ cluster operator

But FIRST get:

* RabbitMQ
* Celery
* Celery Beat
* Flower

working end-to-end.




# To install redis manually use the steps below

## Create Namespace

```bash id="3r8f6d"
kubectl create namespace cache
```

---

## Add Helm Repo

From root directory go inside helm folder where values-redis.yaml resides
```bash
cd helm
```


```bash id="9czq2k"
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update
```

---

## Install Redis

```bash id="2kj8qf"
helm install redis bitnami/redis \
  -n cache \
  -f values-redis.yaml
```

---

## Verify Pods

```bash id="l3tt4w"
kubectl get pods -n cache
```

Expected:

```text id="6f7g1n"
redis-master-0   1/1 Running
```

---

## Verify PVC

```bash id="2okfwd"
kubectl get pvc -n cache
```

Expected:

```text id="dylr77"
STATUS: Bound
```

---

## Verify Services

```bash id="wwt5u6"
kubectl get svc -n cache
```

You should see:

```text id="jlwmrs"
redis-master
redis-headless
```

---

## Test Redis

```bash id="wz9gl9"
kubectl exec -it redis-master-0 -n cache -- redis-cli
```

Then:

```bash id="jlwmrt"
PING
```

Expected:

```text id="jlwmru"
PONG
```

Exit:

```bash id="jlwmrv"
exit
```

---

## Redis URL Inside Kubernetes

Use this connection string from your Flask/Celery apps:

```text id="jlwmrw"
redis://redis-master.cache.svc.cluster.local:6379/0
```


## For local testing

First port forward using the command:
```
kubectl port-forward svc/redis-master 6379:6379 -n cache
```

Then use the connection string:
```
redis://localhost:6379/0
```

Note redis resides in this namespace

```text id="jlwmry"
cache
```

because Kubernetes internal DNS includes namespace.


