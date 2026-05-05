# Kubernetes SRE Lab

A production-grade SRE platform built on k3s (Kubernetes), demonstrating GitOps, CI/CD, and observability practices aligned with real-world cloud migration workflows.

## Stack

| Layer | Technology |
|---|---|
| Kubernetes | k3s on Linux (WSL2) |
| GitOps | ArgoCD |
| CI/CD | GitHub Actions |
| Observability | Prometheus + Grafana + Alertmanager |
| Provisioning | Ansible |
| Security | RBAC, Network Policies, Trivy |

## Project Structure

    k8s-sre-lab/
    ├── manifests/        # Kubernetes manifests (apps, monitoring, argocd)
    ├── ansible/          # Cluster provisioning playbooks
    ├── docs/             # Architecture decisions and runbooks
    └── scripts/          # Helper scripts

## Status

Actively being built — follow the commit history to see each layer added.

## How to run locally

Start the cluster after a WSL restart:

    ./scripts/start-cluster.sh

Verify the cluster is up:

    kubectl get nodes

## Documentation

- Architecture Overview — coming soon
- Runbook: Starting the cluster — coming soon
