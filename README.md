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


