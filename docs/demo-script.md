# Demo Script

Use this flow for a short portfolio walkthrough or interview screen share.

## 1. Platform Overview

Show the architecture diagram:

```text
docs/screenshots/01-architecture.png
```

Explain that the platform demonstrates:

- local Kubernetes with Kind
- Helm packaging
- HTTPS ingress
- health probes and resource requests
- HPA
- persistent PostgreSQL storage
- NetworkPolicy boundaries
- ArgoCD GitOps manifests

## 2. Runtime State

Show:

```bash
kubectl get pods -n users-api -o wide
kubectl get ingress -n users-api
curl -k --resolve users-api.local:443:127.0.0.1 https://users-api.local/readyz
```

Expected result:

```text
users-api Pods are Running
postgres Pod is Running
readyz returns database ok
```

## 3. Helm Release

Show:

```bash
helm list -n users-api
```

Explain that the API is packaged and deployed as a Helm chart with environment-specific values.

## 4. Platform Controls

Show:

```bash
kubectl get hpa -n users-api
kubectl get networkpolicy -n users-api
kubectl get pvc -n users-api
```

Explain how each item maps to production concerns:

- HPA: scale control
- NetworkPolicy: traffic boundaries
- PVC: stateful storage

## 5. GitOps

Show:

```bash
kubectl get applications -n argocd
```

Explain the intended flow:

```text
GitHub change -> ArgoCD detects drift -> ArgoCD syncs -> Kubernetes matches Git
```

If the local ArgoCD controller is blocked by registry image pulls, show `docs/argocd-troubleshooting.md` and explain the recovery path.

## 6. Rolling Update

Show:

```bash
kubectl rollout history deployment/users-api -n users-api
kubectl rollout status deployment/users-api -n users-api
```

Explain that the Deployment uses a rolling update strategy with `maxUnavailable: 0` and `maxSurge: 1`.
