# ArgoCD GitOps - Complete Beginner's Guide

This guide will walk you through setting up and deploying a complete GitOps workflow using ArgoCD, Kubernetes, Prometheus, and Grafana from scratch.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Starting Kubernetes Cluster](#starting-kubernetes-cluster)
4. [Installing ArgoCD](#installing-argocd)
5. [Building and Deploying the Application](#building-and-deploying-the-application)
6. [Setting Up Monitoring](#setting-up-monitoring)
7. [Accessing the Services](#accessing-the-services)
8. [Verifying Your Deployment](#verifying-your-deployment)

---

## Prerequisites

Before starting, ensure you have:
- Windows with WSL2 (Ubuntu 24.04) installed
- Docker Desktop installed and running with WSL2 integration enabled
- At least 8GB RAM and 20GB free disk space
- Basic understanding of terminal commands

---

## Initial Setup

### Step 1: Install Required Tools

Navigate to the scripts directory and run the installation script:

```bash
cd /home/bamideleflint/Argo-CD/ArgoCD-GitOps/scripts
chmod +x install-tools.sh
./install-tools.sh
```

This script installs:
- `kubectl` - Kubernetes command-line tool
- `minikube` - Local Kubernetes cluster
- `argocd` - ArgoCD CLI
- Python dependencies

**Expected output**: You should see messages confirming each tool's installation.

### Step 2: Set Up Python Virtual Environment

Navigate to the application directory:

```bash
cd /home/bamideleflint/Argo-CD/ArgoCD-GitOps/apps/sample-app
```

Create and activate a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
```

Install Python dependencies:

```bash
pip install -r requirements.txt
```

**Expected output**: Flask and its dependencies will be installed.

---

## Starting Kubernetes Cluster

### Step 3: Start Minikube

Start a local Kubernetes cluster:

```bash
minikube start --driver=docker
```

**Expected output**:
```
😄  minikube v1.x.x on Ubuntu 24.04
✨  Using the docker driver
👍  Starting "minikube" primary control-plane node
🏄  Done! kubectl is now configured to use "minikube" cluster
```

**Verification**:
```bash
kubectl get nodes
```

You should see:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.x.x
```

---

## Installing ArgoCD

### Step 4: Create ArgoCD Namespace

```bash
kubectl create namespace argocd
```

### Step 5: Install ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Expected output**: Multiple resources will be created (deployments, services, etc.)

### Step 6: Wait for ArgoCD Pods to be Ready

```bash
kubectl get pods -n argocd --watch
```

Wait until all pods show `1/1` or `2/2` under READY and `Running` under STATUS. Press `Ctrl+C` to exit.

This usually takes 3-5 minutes.

### Step 7: Access ArgoCD UI

In a new terminal, start port-forwarding:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Keep this terminal running.

### Step 8: Get ArgoCD Admin Password

In another terminal:

```bash
argocd admin initial-password -n argocd
```

**Save this password** - you'll need it to log in.

### Step 9: Access ArgoCD

Open your browser and navigate to:
```
http://localhost:8080
```

Login with:
- **Username**: `admin`
- **Password**: (the password from Step 8)

**Note**: You may see a security warning because of the self-signed certificate. Click "Advanced" → "Proceed" to continue.

---

## Building and Deploying the Application

### Step 10: Configure Docker for Minikube

Point your terminal's Docker CLI to Minikube's Docker daemon:

```bash
eval $(minikube docker-env)
```

**Note**: You need to run this command in every new terminal session where you want to build images for Minikube.

### Step 11: Build the Application Image

Navigate to the project root:

```bash
cd /home/bamideleflint/Argo-CD/ArgoCD-GitOps
```

Build the Docker image:

```bash
docker build -t sample-app:latest ./apps/sample-app
```

**Expected output**: 
```
Successfully built [image-id]
Successfully tagged sample-app:latest
```

### Step 12: Deploy Kubernetes Resources

Apply the deployment:

```bash
kubectl apply -f k8s/deployment.yaml
```

Apply the service:

```bash
kubectl apply -f k8s/service.yaml
```

**Verification**:
```bash
kubectl get pods
kubectl get svc
```

You should see `sample-app` pods running and a `sample-app` service.

### Step 13: Deploy ArgoCD Application

```bash
kubectl apply -f argocd/application.yaml
```

**Note**: Make sure the `repoURL` in `argocd/application.yaml` points to your actual GitHub repository.

---

## Setting Up Monitoring

### Step 14: Install Prometheus and Grafana

Add the Prometheus Helm repository:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Create monitoring namespace:

```bash
kubectl create namespace monitoring
```

Install Prometheus:

```bash
helm install prometheus prometheus-community/prometheus -n monitoring
```

Install Grafana:

```bash
helm install grafana grafana/grafana -n monitoring
```

### Step 15: Install ServiceMonitor CRD

```bash
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
```

### Step 16: Apply Custom Monitoring Configs

Apply ServiceMonitor:

```bash
kubectl apply -f k8s/servicemonitor.yaml
```

Apply Prometheus config:

```bash
kubectl apply -f monitoring/prometheus-config.yaml
```

### Step 17: Wait for Monitoring Pods

```bash
kubectl get pods -n monitoring --watch
```

Wait until all pods are `Running`. This can take 5-10 minutes, especially for Grafana.

Press `Ctrl+C` when done.

---

## Accessing the Services

### Step 18: Access Your Sample Application

```bash
minikube service sample-app
```

This will open your application in the browser showing "Hello, DevOps world!"

### Step 19: Access Prometheus

In a new terminal:

```bash
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
```

Access Prometheus at: http://localhost:9090

### Step 20: Access Grafana

In a new terminal:

```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
```

Get Grafana password:

```bash
kubectl get secret -n monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode && echo
```

Access Grafana at: http://localhost:3000

Login with:
- **Username**: `admin`
- **Password**: (output from the command above)

### Step 21: Import Grafana Dashboard

1. In Grafana UI, click **Dashboards** → **Import**
2. Click **Upload JSON file**
3. Select `monitoring/grafana-dashboard.json` from your project
4. Click **Load** → **Import**

---

## Verifying Your Deployment

### Final Verification Checklist

Run these commands to verify everything is working:

```bash
# Check Minikube status
minikube status

# Check all pods in default namespace
kubectl get pods

# Check ArgoCD pods
kubectl get pods -n argocd

# Check monitoring pods
kubectl get pods -n monitoring

# Check services
kubectl get svc
kubectl get svc -n argocd
kubectl get svc -n monitoring

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ServiceMonitor
kubectl get servicemonitor
```

### What You Should See

1. **Minikube**: Running
2. **Sample app pods**: 2/2 Running
3. **ArgoCD pods**: All Running
4. **Monitoring pods**: All Running
5. **Services**: sample-app, argocd-server, prometheus-server, grafana
6. **Applications**: sample-app (in ArgoCD)

---

## Next Steps

Congratulations! You now have a complete GitOps setup with:
- ✅ Local Kubernetes cluster (Minikube)
- ✅ ArgoCD for GitOps deployments
- ✅ Sample Flask application running
- ✅ Prometheus for metrics collection
- ✅ Grafana for visualization
- ✅ ServiceMonitor for app monitoring

### What to Explore Next:

1. **Modify the app**: Edit `apps/sample-app/src/app.py` and rebuild
2. **Add more routes**: Extend the Flask application
3. **Create custom dashboards**: Build your own Grafana dashboards
4. **Add alerts**: Configure Prometheus alerts
5. **Deploy from Git**: Configure ArgoCD to watch your GitHub repo for changes

### Learning Resources:

- ArgoCD Documentation: https://argo-cd.readthedocs.io/
- Kubernetes Basics: https://kubernetes.io/docs/tutorials/
- Prometheus Guide: https://prometheus.io/docs/introduction/overview/
- Grafana Tutorials: https://grafana.com/tutorials/

---

## Quick Reference Commands

```bash
# Start Minikube
minikube start --driver=docker

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete

# View logs of a pod
kubectl logs <pod-name>

# Describe a resource
kubectl describe pod <pod-name>

# Get all resources in a namespace
kubectl get all -n <namespace>

# Delete a resource
kubectl delete -f <file.yaml>

# Restart a deployment
kubectl rollout restart deployment <deployment-name>
```
