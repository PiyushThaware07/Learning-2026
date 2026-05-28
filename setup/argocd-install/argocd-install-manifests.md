# =========================================================
# 1. Install Docker
# =========================================================
sudo apt update -y
sudo apt install -y docker.io curl
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
docker --version
newgrp docker

# =========================================================
# 2. Install Kind
# =========================================================
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind version

# =========================================================
# 3. Install kubectl
# =========================================================
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# =========================================================
# 4. Create Kind Cluster Config
# =========================================================
cat <<EOF > cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

networking:
  apiServerAddress: "172.31.19.178"   # Change to your EC2 private IP
  apiServerPort: 33893

nodes:
  - role: control-plane
    image: kindest/node:v1.33.1

  - role: worker
    image: kindest/node:v1.33.1

  - role: worker
    image: kindest/node:v1.33.1
EOF

# =========================================================
# 5. Create Kubernetes Cluster
# =========================================================
kind create cluster --name argocd-cluster --config cluster.yaml
kubectl cluster-info
kubectl get nodes

# =========================================================
# 6. Install Argo CD using Official Manifests
# =========================================================
kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl get pods -n argocd
kubectl get svc -n argocd

# =========================================================
# 7. Access Argo CD UI
# =========================================================
kubectl port-forward svc/argocd-server \
  -n argocd \
  8080:443 \
  --address=0.0.0.0 &

Open in browser:
https://<INSTANCE_PUBLIC_IP>:8080

# =========================================================
# 8. Get Initial Admin Password
# =========================================================
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

echo ""

Login Credentials
Username: admin
Password: Above Output