# Troubleshooting Guide

## API Is Not Reachable Through HTTPS

Check ingress-nginx:

```bash
kubectl get pods -n ingress-nginx
kubectl get ingress -n users-api
```

Validate with explicit host resolution:

```bash
curl -k --resolve users-api.local:443:127.0.0.1 https://users-api.local/readyz
```

If the cluster was created before port mappings were added, recreate it:

```bash
RESET_CLUSTER=true ./scripts/setup-kind.sh
```

## API Pods Are Not Ready

Check Pods and events:

```bash
kubectl get pods -n users-api
kubectl describe pod -n users-api -l app.kubernetes.io/name=users-api
```

Common causes:

- image was not loaded into Kind
- database Secret is missing
- PostgreSQL is not ready

## PostgreSQL Data Does Not Persist

Check the PVC:

```bash
kubectl get pvc -n users-api
kubectl describe pvc postgres-data -n users-api
```

The PVC should be `Bound`.

## NetworkPolicy Does Not Block Traffic In Kind

Kind's default `kindnet` CNI does not enforce NetworkPolicies. The policies are valid Kubernetes resources, but packet-level enforcement requires a NetworkPolicy-aware CNI such as Calico or Cilium.

## ArgoCD Does Not Become Ready

Check ArgoCD Pods and events:

```bash
kubectl get pods -n argocd
kubectl get events -n argocd --sort-by=.lastTimestamp
```

If Pods are stuck in `ImagePullBackOff`, preload images:

```bash
./scripts/preload-argocd-images.sh
./scripts/install-argocd.sh
```

See `docs/argocd-troubleshooting.md`.
