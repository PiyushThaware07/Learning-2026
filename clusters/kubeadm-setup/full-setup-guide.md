# master : 
sudo hostnamectl set-hostname master

# Worker : 
sudo hostnamectl set-hostname worker

# Disable Swap On Both (Master + Worker) 
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable Kernel Modules On Both (Master + Worker) 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl Settings On Both (Master + Worker) 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system


# Install containerd On Both (Master + Worker)
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kubernetes Components On Both (Master + Worker)
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl

- Add Kubernetes repo:
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

- Install
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Master
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

kubeadm token create --print-join-command
--> you will get something like this : kubeadm join <MASTER-IP>:6443 --token xxxx --discovery-token-ca-cert-hash sha256:xxxx

# Join Worker Node
Eecute on worker node :
kubeadm join <MASTER-IP>:6443 --token xxxx --discovery-token-ca-cert-hash sha256:xxxx

# Verify Cluster (Master Node) 
kubectl get nodes


# Final 
EC2 Master (kube-apiserver)
        |
        |---- Calico Network
        |
EC2 Worker (runs Pods)
