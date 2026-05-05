# Architecture and Design Decisions

This document explains the thinking behind how this platform is built.
Each decision includes why it was made and what the trade-offs are.

---

## Platform overview

The platform follows a GitOps model: Git is the single source of truth
for everything running in the cluster. No manual kubectl apply in
production — every change goes through Git and is applied by ArgoCD.

    Developer → Git push → CI pipeline → ArgoCD → Kubernetes cluster

---

## Decision 1: k3s over minikube or kind

**Chosen:** k3s

**Why:** k3s is a fully certified Kubernetes distribution, not a
development simulation. It ships with Traefik (real ingress), CoreDNS
(real DNS), and the same API as production clusters. Minikube and kind
are great for testing but k3s gives you the same operational experience
as a real cluster while still running on a single machine.

**Trade-off:** k3s doesn't support systemd on WSL2, so it requires a
manual start after each reboot. Solved with scripts/start-cluster.sh.

---

## Decision 2: ArgoCD for GitOps

**Chosen:** ArgoCD

**Why:** ArgoCD is the most widely adopted GitOps tool in the industry.
It provides a visual UI showing exactly what is deployed versus what
Git says should be deployed, and automatically corrects any drift.

selfHeal: true means if someone manually deletes or modifies a resource
in the cluster, ArgoCD notices within seconds and restores it to match
Git. This was validated in this lab — a pod was manually deleted and
recreated automatically in 13 seconds.

**Trade-off:** ArgoCD adds operational complexity (it is itself a set
of 7 pods to maintain). For a very small team, a simpler push-based
approach might be easier. At any meaningful scale, GitOps wins.

---

## Decision 3: kube-prometheus-stack over individual installs

**Chosen:** kube-prometheus-stack Helm chart

**Why:** This chart bundles Prometheus, Grafana, Alertmanager,
kube-state-metrics, and the Prometheus operator together in a tested,
pre-integrated package. Installing each component manually would require
manually wiring up service discovery, scrape configs, and dashboard
provisioning — the chart handles all of this.

**Trade-off:** The chart is opinionated. Customisation requires
understanding its values schema. Several components were disabled
(kubeEtcd, kubeControllerManager, kubeScheduler, kubeProxy) because
they attempt to scrape k3s internals that are not exposed the same way
as in a standard kubeadm cluster.

---

## Decision 4: Network Policies on the app namespace

**Chosen:** Explicit NetworkPolicy on sre-demo-app

**Why:** By default, all pods in Kubernetes can talk to all other pods
across all namespaces. This is a significant security risk. The Network
Policy on sre-demo-app restricts:

- Ingress: only pods in the same namespace and Prometheus in
  sre-monitoring can reach it
- Egress: only DNS (port 53) and same-namespace traffic is allowed

This implements the principle of least privilege at the network level.

**Trade-off:** Network Policies can be hard to debug. If a service stops
responding, a misconfigured policy is often the cause.

---

## Decision 5: Trivy exit-code set to 0 in CI

**Chosen:** Report CVEs but do not fail the pipeline on HIGH severity

**Why:** The base image (python:3.11-slim) has 7 HIGH severity CVEs
with no fix available upstream. Setting exit-code to 1 would permanently
block all deployments until upstream patches the Debian base image —
which is outside our control.

**What we would do in production:**
- Pin to a specific image digest rather than the floating 3.11-slim tag
- Migrate to a distroless image (gcr.io/distroless/python3) which
  eliminates the OS layer entirely and removes most of the attack surface
- Set exit-code: 1 once a clean base image is available
- Add a scheduled scan (weekly) to catch new CVEs in already-deployed images

---

## Namespace design

    argocd/          GitOps controller — manages all other namespaces
    sre-apps/        Application workloads
    sre-monitoring/  Observability stack (Prometheus, Grafana, Alertmanager)

Separating concerns into namespaces means:
- RBAC can be applied per namespace
- Network Policies can reference namespaces by label
- Resource quotas can be set per team or application
- A broken app cannot interfere with the monitoring stack
