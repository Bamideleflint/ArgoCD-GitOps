# ArgoCD-GitOps

A complete GitOps implementation using ArgoCD to manage Kubernetes deployments with monitoring.

## Project Structure

```
├── apps/sample-app/          # Sample Flask application
│   ├── src/app.py           # Application code
│   ├── Dockerfile           # Container image definition
│   └── requirements.txt     # Python dependencies
├── k8s/                     # Kubernetes manifests
│   ├── deployment.yaml      # App deployment configuration
│   ├── service.yaml         # Service definition
│   └── servicemonitor.yaml  # Prometheus monitoring
├── argocd/                  # ArgoCD configuration
│   └── application.yaml     # ArgoCD application manifest
├── monitoring/              # Monitoring stack
│   ├── prometheus-config.yaml
│   └── grafana-dashboard.json
├── documentation/           # Comprehensive guides
│   ├── beginner-guide.md    # Step-by-step setup guide
│   └── troubleshooting.md   # Common errors and solutions
└── scripts/                 # Setup scripts
    └── install-tools.sh     # Install required tools
```

## Prerequisites

- Docker Desktop with WSL2 integration
- kubectl
- Minikube or any Kubernetes cluster
- ArgoCD CLI

## Quick Start

### 1. Install Required Tools
```bash
cd scripts
chmod +x install-tools.sh
./install-tools.sh
```

### 2. Start Minikube
```bash
minikube start --driver=docker
```

### 3. Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 4. Access ArgoCD UI
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get admin password:
```bash
argocd admin initial-password -n argocd
```

### 5. Deploy Application via ArgoCD
```bash
kubectl apply -f argocd/application.yaml
```

### 6. Build and Load Docker Image (for Minikube)
```bash
eval $(minikube docker-env)
docker build -t sample-app:latest ./apps/sample-app
```

## Monitoring

The project includes Prometheus ServiceMonitor and Grafana dashboard configurations for monitoring the deployed application.

## Documentation

📚 **Comprehensive guides available in the `documentation/` folder:**

- **[Beginner's Guide](documentation/beginner-guide.md)** - Complete step-by-step setup guide for beginners
- **[Troubleshooting Guide](documentation/troubleshooting.md)** - Common errors and their solutions

## CI/CD

GitHub Actions workflow automatically:
- Lints Python code
- Builds Docker images
- Runs on every push/PR to main branch

## Features

✅ GitOps workflow with ArgoCD
✅ Kubernetes deployment automation
✅ Prometheus metrics collection
✅ Grafana visualization dashboards
✅ ServiceMonitor for application monitoring
✅ CI/CD pipeline with GitHub Actions
✅ Containerized Flask application
✅ Complete beginner-friendly documentation