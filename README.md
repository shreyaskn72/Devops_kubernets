

## 🔧 Helm Commands

From the root of your repo:

```bash
cd flask_api/helm/flask-api
```

### Install the chart

```bash
helm install flask-api .
```

### Upgrade

```bash
helm upgrade flask-api .
```

### Uninstall

```bash
helm uninstall flask-api
```

---

Excellent — that’s actually a **very common Helm/Kubectl issue** in Codespaces.
Let’s unpack it step-by-step 👇

---

## 🧠 Why It Happens

Your error:

```
Error: UPGRADE FAILED: Kubernetes cluster unreachable: Get "http://localhost:8080/version": dial tcp [::1]:8080: connect: connection refused
```

means **Helm cannot find or talk to a Kubernetes cluster**.

Helm is just a *templating and deployment client* — it talks to a Kubernetes API server through your local kubeconfig (usually at `~/.kube/config`).
But in **GitHub Codespaces**, you **don’t have any Kubernetes cluster running** by default.

---

## ✅ Your Options

Depending on what you want to do, here are your choices:

### **Option 1: Run a Local Kubernetes Cluster (for testing in Codespaces)**

Use **Minikube** or **Kind** to start a lightweight local cluster.

#### 🧩 Install Kind

```bash
sudo apt update && sudo apt install -y ca-certificates curl
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

#### 🧩 Create a Cluster

```bash
kind create cluster --name dev-cluster
```

Now check:

```bash
kubectl cluster-info
```

You should see something like:

```
Kubernetes control plane is running at https://127.0.0.1:XXXXX
```

Then you can safely run:

```bash
helm install flask-api .
```

---

### **Option 2: Connect to a Remote Cluster (like EKS, GKE, AKS, or K3s)**

If you already have a cluster somewhere:

1. Get your **kubeconfig** file from your cloud provider.
2. Save it in your Codespace:

   ```bash
   mkdir -p ~/.kube
   vi ~/.kube/config
   ```
3. Paste the content and save it.
4. Test:

   ```bash
   kubectl get nodes
   ```

   If that works → Helm will also work.

---

### **Option 3: Just Template Your Chart (No Cluster Needed)**

If you just want to **validate your Helm chart**, render it into raw Kubernetes YAML **without connecting to a cluster**:

```bash
helm template flask-api .
```

This command:

* Doesn’t need a cluster.
* Outputs the rendered manifests.
* Helps check your syntax before actual deployment.

---

## 🚀 Recommended Flow in Codespaces

If you’re just building and testing:

```bash
helm template flask-api .
```

If you want to simulate real deployment:

```bash
kind create cluster
helm install flask-api .
kubectl get pods
```

---




🎉 Perfect — that means your **Helm chart successfully deployed** to your Kubernetes cluster!

Here’s what just happened and what you can do next 👇

---

## ✅ What That Output Means

```
Release "flask-api" has been upgraded. Happy Helming!
```

* Your Helm chart (`flask-api`) was **installed or upgraded** (revision `2`).
* Kubernetes resources like Deployment, Service, and possibly Ingress were created.
* Status `deployed` confirms everything applied successfully.

---

## 🔍 Check That It’s Running

Run these commands to verify your Flask app is up:

```bash
kubectl get all
```

You should see something like:

```
NAME                                 READY   STATUS    RESTARTS   AGE
pod/flask-api-xxxxxxxxxx-yyyyy       1/1     Running   0          1m

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/flask-api    ClusterIP   10.96.182.233   <none>        80/TCP    1m

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/flask-api       1/1     1            1           1m
```

---

## 🌐 Access Your App

From the Helm `NOTES.txt`, you can port-forward the service:

```bash
export POD_NAME=$(kubectl get pods -l "app=flask-api" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:5000
```

Then open in your browser:
👉 **[http://127.0.0.1:8080](http://127.0.0.1:8080)**

You should see your Flask “Hello World” response.

---

## 🧹 Optional Cleanup

When you’re done testing:

```bash
helm uninstall flask-api
```

This removes all resources created by the chart.

---

## 💡 Pro Tip

To inspect what Helm actually applied to your cluster:

```bash
helm get manifest flask-api
```

That shows the full Kubernetes YAML generated from your chart.

---

