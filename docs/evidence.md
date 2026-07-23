# Phase 5 Evidence

This page is the fast review path for the platform.

## Screenshots

| Evidence | File |
| --- | --- |
| Architecture diagram | `docs/screenshots/01-architecture.png` |
| Users API and PostgreSQL Pods | `docs/screenshots/02-pods-running.png` |
| HTTPS Ingress and readiness response | `docs/screenshots/03-ingress-https.png` |
| Helm release | `docs/screenshots/04-helm-release.png` |
| HPA | `docs/screenshots/05-hpa.png` |
| NetworkPolicies | `docs/screenshots/06-network-policies.png` |
| PostgreSQL PVC | `docs/screenshots/07-pvc.png` |
| ArgoCD Applications | `docs/screenshots/08-argocd-synced.png` |
| Rolling update history/status | `docs/screenshots/09-rolling-update.png` |

Raw command output is stored in `docs/evidence/`.

## Verified Locally

The following capabilities are backed by captured command output:

- Users API Pods are running.
- PostgreSQL is running with a bound PVC.
- HTTPS Ingress responds successfully through `users-api.local`.
- Helm release `users-api` is deployed.
- HPA exists and targets the Users API Deployment.
- NetworkPolicies define default-deny and explicit allow rules.
- Rolling update history and rollout status are available.
- ArgoCD CRDs and Application resources exist.

## Current ArgoCD Note

The ArgoCD Application manifests are present and valid, and the Application CRDs are installed. In the captured local run, the ArgoCD controller Pods could not become ready because the Kind node could not pull `quay.io/argoproj/argocd:v2.10.7`.

Observed registry/network errors included:

```text
ImagePullBackOff
TLS handshake timeout
connection refused
lookup quay.io ... no such host
```

See `docs/argocd-troubleshooting.md` for the recovery path.
