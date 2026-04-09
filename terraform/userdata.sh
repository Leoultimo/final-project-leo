#!/bin/bash
# =============================================================================
#  EC2 User Data – k3s + Helm + QuakeWatch chart bootstrap
#  Runs as root on first boot (Amazon Linux 2023)
# =============================================================================
set -euo pipefail
exec > >(tee /var/log/userdata.log | logger -t userdata) 2>&1

echo "=========================================="
echo " Starting QuakeWatch k3s bootstrap"
echo " $(date -u)"
echo "=========================================="

# ── 1. System update & base packages ──────────────────────────────────────
dnf update -y
dnf install -y git curl tar

# ── 2. Install k3s (single-node, no HA) ──────────────────────────────────
echo "→ Installing k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --disable traefik \
  --write-kubeconfig-mode 644" sh -

# Wait until the k3s service is fully up and the API is responding
echo "→ Waiting for k3s to become ready..."
timeout 120 bash -c 'until kubectl get nodes 2>/dev/null | grep -q " Ready"; do sleep 5; done'
echo "→ k3s node is Ready."

# Make kubectl available to ec2-user without sudo
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc

# ── 3. Install Helm ────────────────────────────────────────────────────────
echo "→ Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ── 4. Clone QuakeWatch Helm chart repository ─────────────────────────────
REPO_URL="${helm_chart_repo}"
CLONE_DIR="/opt/quakewatch"

echo "→ Cloning $REPO_URL into $CLONE_DIR..."
git clone "$REPO_URL" "$CLONE_DIR"
chown -R ec2-user:ec2-user "$CLONE_DIR"
echo "→ Repository cloned successfully."

# ── 5. Deploy the QuakeWatch Helm chart ───────────────────────────────────
# Adjust the chart path below if the chart lives in a sub-directory
CHART_PATH="$CLONE_DIR"

# Look for a charts/ or helm/ sub-directory if root has no Chart.yaml
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
  for sub in helm chart charts quakewatch; do
    if [ -f "$CHART_PATH/$sub/Chart.yaml" ]; then
      CHART_PATH="$CHART_PATH/$sub"
      break
    fi
  done
fi

if [ -f "$CHART_PATH/Chart.yaml" ]; then
  echo "→ Installing QuakeWatch Helm chart from $CHART_PATH..."
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  helm upgrade --install quakewatch "$CHART_PATH" \
    --namespace quakewatch \
    --create-namespace \
    --wait \
    --timeout 5m
  echo "→ Helm release deployed successfully."
else
  echo "⚠  Chart.yaml not found in $CLONE_DIR – skipping Helm install."
  echo "   Manually run: helm install quakewatch <chart-path>"
fi

# ── 6. Final status ────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo " Bootstrap complete – $(date -u)"
echo "=========================================="
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes -o wide
kubectl get pods -A
