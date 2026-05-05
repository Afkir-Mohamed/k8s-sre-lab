# Kubernetes SRE Lab

A production-grade SRE platform built from scratch on k3s, demonstrating the full GitOps workflow used by cloud migration teams. Every layer — from cluster provisioning to observability to automated deployment — is built and documented as it would be in a real engineering team.

## What this project demonstrates

| Skill | Implementation |
|---|---|
| Kubernetes | k3s single-node cluster on Linux (WSL2 Ubuntu 24.04) |
| GitOps | ArgoCD with selfHeal and drift detection proven |
| CI/CD | GitHub Actions — lint, security scan, ArgoCD validation |
| Observability | Prometheus + Grafana + Alertmanager (kube-prometheus-stack) |
| Security | RBAC, Network Policies, Trivy CVE scanning in pipeline |
| Provisioning | Ansible playbooks with idempotency verified |
| IaC | Helm values files for all deployed stacks |

## Architecture

    Git repository (this repo)
         |
         | push
         v
    GitHub Actions CI
    - kubeconform manifest linting
    - Trivy container security scan
    - ArgoCD manifest validation
         |
         | on success
         v
    ArgoCD (GitOps controller)
    - watches manifests/apps/
    - selfHeal: recreates deleted resources automatically
    - prune: removes resources deleted from Git
         |
         | deploys to
         v
    k3s Kubernetes cluster
    ├── sre-apps/          (application workloads)
    ├── sre-monitoring/    (Prometheus + Grafana + Alertmanager)
    └── argocd/            (GitOps controller)

## Key results

- GitOps self-healing validated: deleted a running pod, ArgoCD
  recreated it in 13 seconds with zero manual intervention
- CI pipeline catches schema errors, logical errors, and HIGH/CRITICAL
  CVEs before they reach the cluster
- Trivy found 7 HIGH severity CVEs in python:3.11-slim base image
  (all in Debian OS layer, no fix available upstream at time of scan)
- Ansible idempotency proven: second playbook run shows changed=0

## Project structure

    k8s-sre-lab/
    ├── .github/workflows/    # GitHub Actions CI pipeline
    ├── manifests/
    │   ├── apps/             # sre-demo-app (deployment, service,
    │   │                     # serviceaccount, networkpolicy)
    │   ├── monitoring/       # Prometheus stack Helm values
    │   └── argocd/           # ArgoCD Application definitions
    ├── ansible/              # Cluster provisioning playbooks
    ├── docs/                 # Architecture decisions and runbooks
    └── scripts/              # Cluster startup script

## How to run locally

Requirements: Windows with WSL2 (Ubuntu 24.04), 4GB RAM minimum

    # 1. Start the cluster (required after every WSL restart)
    ./scripts/start-cluster.sh

    # 2. Verify cluster is healthy
    kubectl get nodes
    kubectl get pods -A

    # 3. Access Grafana (open http://localhost:3001)
    kubectl port-forward service/kube-prometheus-stack-grafana \
      3001:80 -n sre-monitoring

    # 4. Access ArgoCD (open https://localhost:8080)
    kubectl port-forward service/argocd-server 8080:443 -n argocd

    # 5. Run Ansible provisioning
    ansible-playbook ansible/provision-cluster.yaml

## Documentation

- [Architecture and design decisions](docs/architecture.md)
- [Runbook: Starting the cluster](docs/runbooks/start-cluster.md)

## Security findings

Trivy CVE scan on python:3.11-slim (May 2026):
- 7 HIGH severity CVEs in Debian OS layer (libcap, ncurses, systemd)
- 0 CRITICAL CVEs
- No fixed versions available upstream at time of scan
- Remediation path: migrate to distroless/python or pin to patched digest
