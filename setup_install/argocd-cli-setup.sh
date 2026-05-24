#!/bin/bash

set -e

# =========================================================
# Detect Public IP Automatically
# =========================================================
PUBLIC_IP=$(curl -s ifconfig.me || echo "YOUR_PUBLIC_IP")

ARGOCD_SERVER="${PUBLIC_IP}:8080"
ARGO_NAMESPACE="argocd"

# =========================================================
# Fetch ArgoCD Admin Password Dynamically
# =========================================================
ARGO_PASSWORD=$(kubectl get secret argocd-initial-admin-secret \
  -n ${ARGO_NAMESPACE} \
  -o jsonpath="{.data.password}" | base64 -d)

# =========================================================
# Banner
# =========================================================
echo "========================================================="
echo " ArgoCD CLI Setup"
echo "========================================================="
echo ""

echo "Detected Public IP : ${PUBLIC_IP}"
echo "Detected Password  : ${ARGO_PASSWORD}"
echo ""

# =========================================================
# 1. Install ArgoCD CLI
# =========================================================
echo "[1/4] Installing ArgoCD CLI..."

curl -sSL -o argocd-linux-amd64 \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

rm -f argocd-linux-amd64

echo ""
echo "ArgoCD CLI Installed Successfully"
echo ""

# =========================================================
# 2. Verify Installation
# =========================================================
echo "[2/4] Verifying Installation..."

argocd version --client

echo ""
echo "Verification Completed"
echo ""

# =========================================================
# 3. Login to ArgoCD
# =========================================================
echo "[3/4] Logging into ArgoCD..."

argocd login ${ARGOCD_SERVER} \
  --username admin \
  --password ${ARGO_PASSWORD} \
  --insecure

echo ""
echo "Login Successful"
echo ""

# =========================================================
# 4. Get User Info
# =========================================================
echo "[4/4] Fetching User Information..."
echo ""

argocd account get-user-info

echo ""
echo "========================================================="
echo " ArgoCD CLI Setup Completed"
echo "========================================================="
echo ""

echo "URL      : https://${PUBLIC_IP}:8080"
echo "Username : admin"
echo "Password : ${ARGO_PASSWORD}"
echo ""