# Troubleshooting Guide - ArgoCD GitOps Project

This guide covers common errors and their solutions when working with this ArgoCD GitOps project.

## Table of Contents
1. [Minikube Issues](#minikube-issues)
2. [ArgoCD Issues](#argocd-issues)
3. [Docker and Container Issues](#docker-and-container-issues)
4. [Python and Flask Issues](#python-and-flask-issues)
5. [Kubernetes Resources Issues](#kubernetes-resources-issues)
6. [Monitoring Issues](#monitoring-issues)
7. [Network and Port Issues](#network-and-port-issues)

---

## Minikube Issues

### Error: Ports in Use (8443, 10259)

**Error Message**:
```
[ERROR Port-8443]: Port 8443 is in use
[ERROR Port-10259]: Port 10259 is in use
error: error execution phase preflight: preflight checks failed
```

**Cause**: Previous Minikube instance is still running or crashed without cleanup.

**Solution**:
```bash
# Delete the existing cluster
minikube delete

# Start fresh
minikube start --driver=docker
```

**Verification**:
```bash
minikube status
kubectl get nodes
```

---

### Error: Minikube Won't Start - Docker Not Running

**Error Message**:
```
❌  Exiting due to PROVIDER_DOCKER_NOT_RUNNING
```

**Cause**: Docker Desktop is not running or WSL integration is not enabled.

**Solution**:
1. Open Docker Desktop
2. Go to Settings → Resources → WSL Integration
3. Enable integration for Ubuntu-24.04
4. Click "Apply & Restart"
5. Wait for Docker to fully start
6. Try `minikube start --driver=docker` again

---

### Error: Insufficient Resources

**Error Message**:
```
❌  Exiting due to RSRC_INSUFFICIENT_CORES
```

**Cause**: Not enough CPU/memory allocated to Docker.

**Solution**:
1. Open Docker Desktop → Settings → Resources
2. Increase CPU to at least 2 cores
3. Increase Memory to at least 4GB (8GB recommended)
4. Click "Apply & Restart"

---

## ArgoCD Issues

### Error: Pod Not Running - Port Forward Failed

**Error Message**:
```
error: unable to forward port because pod is not running. Current status=Pending
```

**Cause**: ArgoCD pods are still initializing.

**Solution**:
```bash
# Check pod status
kubectl get pods -n argocd

# Wait for all pods to be Running
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Then retry port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Expected**: All pods should show `1/1` or `2/2` under READY column.

---

### Error: Cannot Access ArgoCD UI

**Error Message**: Browser shows "This site can't be reached"

**Cause**: Port-forward is not running or terminated.

**Solution**:
```bash
# Ensure port-forward is running in a terminal
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Keep this terminal open
# Access http://localhost:8080 in browser
```

**Alternative**: Try a different port if 8080 is in use:
```bash
kubectl port-forward svc/argocd-server -n argocd 8888:443
# Then access http://localhost:8888
```

---

### Error: Forgot ArgoCD Admin Password

**Solution**:
```bash
# Get the initial password
argocd admin initial-password -n argocd

# Or extract from secret
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode && echo
```

---

## Docker and Container Issues

### Error: Cannot Build Docker Image

**Error Message**:
```
Cannot connect to the Docker daemon
```

**Cause**: Docker daemon not accessible or Minikube Docker environment not set.

**Solution**:
```bash
# For Minikube, use Minikube's Docker daemon
eval $(minikube docker-env)

# Verify Docker is accessible
docker ps

# Rebuild image
docker build -t sample-app:latest ./apps/sample-app
```

**Note**: Run `eval $(minikube docker-env)` in every new terminal session.

---

### Error: Image Pull Failed - ImagePullBackOff

**Error Message**:
```
Failed to pull image "sample-app:latest": rpc error: code = Unknown
```

**Cause**: Image doesn't exist in Minikube's Docker registry.

**Solution**:
```bash
# Set Docker environment to Minikube
eval $(minikube docker-env)

# Rebuild the image
cd /home/bamideleflint/Argo-CD/ArgoCD-GitOps
docker build -t sample-app:latest ./apps/sample-app

# Verify image exists
docker images | grep sample-app

# Update deployment to use imagePullPolicy: IfNotPresent (already set)
kubectl get deployment sample-app -o yaml | grep imagePullPolicy
```

---

## Python and Flask Issues

### Error: Import "flask" Could Not Be Resolved

**Error Message**:
```
Import "flask" could not be resolved
```

**Cause**: Flask is not installed in your Python environment.

**Solution**:
```bash
# Navigate to app directory
cd /home/bamideleflint/Argo-CD/ArgoCD-GitOps/apps/sample-app

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

**IDE Configuration**: Configure your IDE to use the virtual environment at:
```
/home/bamideleflint/Argo-CD/ArgoCD-GitOps/apps/sample-app/venv
```

---

### Error: Externally Managed Environment

**Error Message**:
```
error: externally-managed-environment
× This environment is externally managed
```

**Cause**: Ubuntu 24.04 with Python 3.12 prevents direct pip installs (PEP 668).

**Solution**: Always use virtual environments:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**Never use**: `pip install --break-system-packages` (dangerous!)

---

## Kubernetes Resources Issues

### Error: Service Not Found

**Error Message**:
```
❌  Exiting due to SVC_NOT_FOUND: Service 'sample-app-service' was not found
```

**Cause**: Wrong service name.

**Solution**:
```bash
# List all services
kubectl get svc

# Use the correct service name
minikube service sample-app

# Or check the service.yaml file for the name
grep "name:" k8s/service.yaml
```

---

### Error: No Matches for Kind ServiceMonitor

**Error Message**:
```
error: no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
ensure CRDs are installed first
```

**Cause**: Prometheus Operator CRDs not installed.

**Solution**:
```bash
# Install ServiceMonitor CRD
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml

# Then apply ServiceMonitor
kubectl apply -f k8s/servicemonitor.yaml

# Verify CRD exists
kubectl get crd servicemonitors.monitoring.coreos.com
```

---

### Error: Path Does Not Exist

**Error Message**:
```
error: the path "../argocd/application.yaml" does not exist
```

**Cause**: Wrong relative path from current directory.

**Solution**:
```bash
# Check your current directory
pwd

# Navigate to project root first
cd /home/bamideleflint/Argo-CD/ArgoCD-GitOps

# Then use correct relative path
kubectl apply -f argocd/application.yaml

# Or use absolute path
kubectl apply -f /home/bamideleflint/Argo-CD/ArgoCD-GitOps/argocd/application.yaml
```

---

## Monitoring Issues

### Error: Grafana Pod Keeps Restarting

**Error Message**:
```
Warning  Unhealthy  Container grafana failed liveness probe, will be restarted
```

**Cause**: Grafana is performing long database migrations on first startup, causing health check timeouts.

**Solution**:
```bash
# Wait longer - Grafana initialization can take 10-15 minutes
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --watch

# Check logs to see progress
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50

# Once pod shows 1/1 Running, it's ready
```

**Alternative Access**: Port-forward directly to the pod:
```bash
kubectl port-forward -n monitoring $(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
```

---

### Error: Cannot Access Grafana - Connection Refused

**Error Message**:
```
error forwarding port 3000 to pod: error forwarding port 3000: exit status 1
```

**Cause**: 
1. Grafana pod is not fully ready
2. Using wrong port mapping

**Solution**:
```bash
# Check if Grafana pod is ready
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Should show 1/1 Running
# If 0/1, wait for it to be ready

# Use correct port-forward command
kubectl port-forward svc/grafana -n monitoring 3000:80
```

---

### Error: Prometheus Server Not Ready

**Error Message**:
```
error: unable to forward port because pod is not running. Current status=Pending
```

**Cause**: Prometheus server pod has 2 containers and takes time to start.

**Solution**:
```bash
# Check pod status
kubectl get pods -n monitoring | grep prometheus-server

# Wait for 2/2 Running
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Then port-forward
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
```

---

### Error: Forgot Grafana Password

**Solution**:
```bash
# Get Grafana admin password
kubectl get secret -n monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode && echo
```

**Default credentials**:
- Username: `admin`
- Password: (from command above, often `admin` by default)

---

## Network and Port Issues

### Error: Port Already in Use

**Error Message**:
```
bind: address already in use
```

**Cause**: Another process is using the port.

**Solution**:
```bash
# Find what's using the port (e.g., 3000)
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use a different port
kubectl port-forward svc/grafana -n monitoring 3001:80
```

---

### Error: Cannot Access localhost URLs

**Cause**: Port-forward not running or firewall blocking.

**Solution**:
```bash
# Ensure port-forward is active
# Run in separate terminal and keep it open

# For ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# For Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# For Prometheus
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
```

**Firewall Check**: Temporarily disable firewall to test:
```bash
# Check Windows Firewall settings
# Or run browser as administrator
```

---

## General Debugging Commands

### Check Resource Status
```bash
# All pods in all namespaces
kubectl get pods -A

# Specific namespace
kubectl get pods -n <namespace>

# All resources
kubectl get all -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### View Logs
```bash
# Pod logs
kubectl logs <pod-name> -n <namespace>

# Follow logs
kubectl logs -f <pod-name> -n <namespace>

# Previous container logs (after crash)
kubectl logs <pod-name> -n <namespace> --previous

# All containers in pod
kubectl logs <pod-name> -n <namespace> --all-containers
```

### Describe Resources
```bash
# Detailed pod info
kubectl describe pod <pod-name> -n <namespace>

# Check events at bottom of output
kubectl describe pod <pod-name> -n <namespace> | grep -A 20 Events
```

### Delete and Recreate
```bash
# Delete pod (will auto-restart)
kubectl delete pod <pod-name> -n <namespace>

# Delete and recreate deployment
kubectl delete -f <file.yaml>
kubectl apply -f <file.yaml>

# Restart deployment
kubectl rollout restart deployment <deployment-name> -n <namespace>
```

---

## Getting Help

If you encounter an issue not listed here:

1. **Check pod logs**: `kubectl logs <pod-name> -n <namespace>`
2. **Describe the resource**: `kubectl describe pod <pod-name> -n <namespace>`
3. **Check events**: `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`
4. **Search the error message**: Copy exact error to Google/Stack Overflow
5. **Check official docs**:
   - ArgoCD: https://argo-cd.readthedocs.io/
   - Kubernetes: https://kubernetes.io/docs/
   - Minikube: https://minikube.sigs.k8s.io/docs/

---

## Clean Slate - Start Over

If everything is broken and you want to start fresh:

```bash
# Delete everything
minikube delete

# Remove Docker images (if needed)
docker system prune -a

# Start from beginning
minikube start --driver=docker

# Reinstall everything following beginner-guide.md
```

**Warning**: This will delete ALL Minikube data!
