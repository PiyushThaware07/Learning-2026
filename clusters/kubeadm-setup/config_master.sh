#!/usr/bin/env bash
set -euo pipefail

CONFIGURE_LOCATION="/usr/local/bin"
K8S_VERSION="v1.29"

sudo mkdir -p "$CONFIGURE_LOCATION"

echo "==> Setting hostname"
sudo hostnamectl set-hostname master

echo "==> Disabling swap permanently"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "==> Loading kernel modules"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "==> Sysctl settings"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo "==> Installing containerd"
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# 🔥 IMPORTANT FIX: required for Kubernetes stability
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd

echo "==> Installing Kubernetes tools"
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "==> Enabling kubelet"
sudo systemctl enable kubelet

echo "==> Initializing Kubernetes cluster (idempotent check)"
if [ ! -f /etc/kubernetes/admin.conf ]; then
  sudo kubeadm init --pod-network-cidr=192.168.0.0/16
fi

echo "==> Setting kubeconfig"
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

echo "==> Starting control plane wait loop"
for i in {1..30}; do
  if kubectl get nodes >/dev/null 2>&1; then
    echo "Kubernetes API is ready"
    break
  fi
  echo "Waiting for API server... ($i/30)"
  sleep 5
done

echo "==> Installing Calico CNI"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

echo "==> Generating join command"
JOIN_CMD=$(sudo kubeadm token create --print-join-command)

echo "$JOIN_CMD" | sudo tee "$CONFIGURE_LOCATION/kubeadm-join.sh" > /dev/null
sudo chmod +x "$CONFIGURE_LOCATION/kubeadm-join.sh"

echo "==> Backup kubeconfig"
sudo cp -f /etc/kubernetes/admin.conf "$CONFIGURE_LOCATION/kubeconfig"

echo "✅ Master setup complete"
echo "Join command: $CONFIGURE_LOCATION/kubeadm-join.sh"
