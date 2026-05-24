#!/bin/bash

set -e

# =========================================================
# Variables
# =========================================================
CLUSTER_NAME="argocd-cluster"
ARGO_NAMESPACE="argocd"
KIND_NODE_VERSION="v1.33.1"

PRIVATE_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s ifconfig.me || echo "YOUR_PUBLIC_IP")

# =========================================================
# Banner
# =========================================================
echo "========================================================="
echo " ArgoCD + Kind Kubernetes Setup"
echo "========================================================="
echo ""

# =========================================================
# 1. Install Docker
# =========================================================
echo "[1/9] Installing Docker..."

sudo apt update -y
sudo apt install -y docker.io curl

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER || true

docker --version

echo ""
echo "Docker Installed Successfully"
echo ""

# =========================================================
# 2. Install Kind
# =========================================================
echo "[2/9] Installing Kind..."

if ! command -v kind >/dev/null 2>&1; then
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64

  chmod +x ./kind

  sudo mv ./kind /usr/local/bin/kind
fi

kind version

echo ""
echo "Kind Installed Successfully"
echo ""

# =========================================================
# 3. Install kubectl
# =========================================================
echo "[3/9] Installing kubectl..."

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

chmod +x kubectl

sudo mv -f kubectl /usr/local/bin/

kubectl version --client

echo ""
echo "kubectl Installed Successfully"
echo ""

# =========================================================
# 4. Install Helm
# =========================================================
echo "[4/9] Installing Helm..."

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh

./get_helm.sh

rm -f get_helm.sh

helm version

echo ""
echo "Helm Installed Successfully"
echo ""

# =========================================================
# 5. Create Kind Cluster Config
# =========================================================
echo "[5/9] Creating cluster.yaml..."

cat <<EOF > cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

networking:
  apiServerAddress: "${PRIVATE_IP}"
  apiServerPort: 33893

nodes:
  - role: control-plane
    image: kindest/node:${KIND_NODE_VERSION}

  - role: worker
    image: kindest/node:${KIND_NODE_VERSION}

  - role: worker
    image: kindest/node:${KIND_NODE_VERSION}
EOF

echo ""
echo "cluster.yaml Created"
echo ""

# =========================================================
# 6. Create Kubernetes Cluster
# =========================================================
echo "[6/9] Creating Kind Cluster..."

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo ""
  echo "Cluster already exists. Skipping creation."
  echo ""
else
  kind create cluster \
    --name ${CLUSTER_NAME} \
    --config cluster.yaml
fi

echo ""
echo "Waiting for Kubernetes Nodes to become Ready..."
echo ""

kubectl wait --for=condition=Ready nodes --all --timeout=300s

kubectl get nodes

echo ""
echo "Kubernetes Cluster Ready"
echo ""

# =========================================================
# 7. Install Argo CD using Helm
# =========================================================
echo "[7/9] Installing Argo CD..."

helm repo add argo https://argoproj.github.io/argo-helm || true

helm repo update

kubectl create namespace ${ARGO_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

if helm list -n ${ARGO_NAMESPACE} | grep -q "^argocd"; then
  echo ""
  echo "Argo CD already installed. Skipping Helm install."
  echo ""
else
  helm install argocd argo/argo-cd \
    -n ${ARGO_NAMESPACE}
fi

echo ""
echo "Waiting for Argo CD Pods..."
echo ""

kubectl rollout status deployment/argocd-server \
  -n ${ARGO_NAMESPACE} \
  --timeout=300s

kubectl get pods -n ${ARGO_NAMESPACE}

echo ""
echo "Argo CD Installed Successfully"
echo ""

# =========================================================
# 8. Access Argo CD UI
# =========================================================
echo "[8/9] Starting Port Forward..."

pkill -f "kubectl port-forward svc/argocd-server" || true

nohup kubectl port-forward svc/argocd-server \
  -n ${ARGO_NAMESPACE} \
  8080:443 \
  --address=0.0.0.0 >/dev/null 2>&1 &

sleep 5

echo ""
echo "========================================================="
echo " Argo CD UI"
echo "========================================================="
echo ""
echo "URL      : https://${PUBLIC_IP}:8080"
echo "Username : admin"
echo ""

# =========================================================
# 9. Get Initial Admin Password
# =========================================================
echo "[9/9] Fetching Admin Password..."

ARGO_PASSWORD=$(kubectl get secret argocd-initial-admin-secret \
  -n ${ARGO_NAMESPACE} \
  -o jsonpath="{.data.password}" | base64 -d)

echo "Password : ${ARGO_PASSWORD}"
echo ""

echo "========================================================="
echo " Setup Completed Successfully"
echo "========================================================="
echo ""