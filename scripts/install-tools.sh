#!/bin/bash
set -e

# Update package list
sudo apt update

# Install curl, Docker, and Python
sudo apt install -y curl python3 python3-pip

# Install kubectl
if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi

# Install Minikube
if ! command -v minikube &> /dev/null; then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
  sudo dpkg -i minikube_latest_amd64.deb
fi

# Install ArgoCD CLI
if ! command -v argocd &> /dev/null; then
  curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
fi

# Inform user about Docker (install Docker Desktop on Windows for WSL2)
echo "Please make sure Docker Desktop is installed and integrated with WSL for Docker support."

echo "All DevOps tools installed. You may need to restart your WSL terminal."