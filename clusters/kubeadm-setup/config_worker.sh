#!/usr/bin/env bash
set -e

CONFIGURE_LOCATION="/usr/local/bin"

sudo mkdir -p "$CONFIGURE_LOCATION"

# Hostname
sudo hostnamectl set-hostname worker

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

# containerd
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo systemctl restart containerd
sudo systemctl enable containerd

# Kubernetes dependencies
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet

# ---- JOIN CLUSTER ----
JOIN_FILE="$CONFIGURE_LOCATION/kubeadm-join.sh"

if [ ! -f "$JOIN_FILE" ]; then
  echo "ERROR: Join file not found at $JOIN_FILE"
  echo "Copy it from master:"
  echo "scp master:/usr/local/bin/kubeadm-join.sh $JOIN_FILE"
  exit 1
fi

if [ ! -s "$JOIN_FILE" ]; then
  echo "ERROR: Join file is empty. Regenerate on master:"
  echo "sudo kubeadm token create --print-join-command"
  exit 1
fi

# FIX: permission issue
sudo chmod +x "$JOIN_FILE"

echo "Joining Kubernetes cluster..."
sudo bash "$JOIN_FILE"

echo "Worker node successfully joined cluster."
