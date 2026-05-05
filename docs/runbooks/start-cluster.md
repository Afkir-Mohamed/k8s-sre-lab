# Runbook: Starting the cluster

Use this runbook after every WSL2 restart or Windows reboot.

---

## When to use this

k3s does not auto-start on WSL2 because WSL2 uses init rather than
systemd. Every time Windows restarts or WSL2 is reset, the cluster
needs to be started manually.

---

## Steps

**1. Open WSL2 terminal and navigate to the project:**

    cd ~/projects/k8s-sre-lab

**2. Run the startup script:**

    ./scripts/start-cluster.sh

The script starts k3s in the background and waits 15 seconds for it
to initialise. You will see the node status printed at the end.

**3. Verify the cluster is healthy:**

    kubectl get nodes

Expected output:

    NAME              STATUS   ROLES           AGE   VERSION
    desktop-xxxxxxx   Ready    control-plane   Xd    v1.35.x+k3s1

**4. Verify all pods are running:**

    kubectl get pods -A

Wait 60-90 seconds after startup for all pods to reach Running status.
Some pods will show Pending or ContainerCreating briefly — this is normal.

**5. Restore port forwards if needed:**

Grafana (http://localhost:3001):

    kubectl port-forward service/kube-prometheus-stack-grafana \
      3001:80 -n sre-monitoring &

ArgoCD (https://localhost:8080):

    kubectl port-forward service/argocd-server 8080:443 -n argocd &

---

## Troubleshooting

**kubectl: connection refused**
k3s is not running yet. Wait 30 seconds and try again, or check logs:

    tail -f ~/projects/k8s-sre-lab/k3s.log

**Pod stuck in Pending**
Usually a port conflict or resource constraint. Check events:

    kubectl describe pod <pod-name> -n <namespace> | grep -A 10 Events

**ArgoCD shows Unknown sync status**
The application controller is still warming up. Wait 2 minutes and
check again. If it persists, restart the controller:

    kubectl rollout restart statefulset/argocd-application-controller -n argocd
