#!/usr/bin/env bash
set -e

CONFIGURE_LOCATION="/usr/local/bin"

# Install docker
sudo apt update -y
sudo apt install -y docker.io curl
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
docker --version

# Install kubectl 
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl "$CONFIGURE_LOCATION/"
kubectl version --client --output=yaml

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 "$CONFIGURE_LOCATION/minikube"
minikube version
