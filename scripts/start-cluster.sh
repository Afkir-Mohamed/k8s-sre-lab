#!/bin/bash
# Start k3s cluster (required after every WSL restart)
# Logs are written to k3s.log in the project root

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../k3s.log"

echo "Starting k3s cluster..."
sudo k3s server --write-kubeconfig-mode 644 > "$LOG_FILE" 2>&1 &

echo "Waiting for cluster to be ready..."
sleep 15

kubectl get nodes
echo "Cluster is ready. Run 'kubectl get nodes' to verify."
