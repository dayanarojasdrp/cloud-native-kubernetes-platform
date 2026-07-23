# Demo Video Outline

Target length: 3-5 minutes.

## 0:00 - 0:30 Overview

Show the repository README and architecture screenshot.

Say:

```text
This is a local production-style Kubernetes platform for a Go Users API. It demonstrates Helm packaging, HTTPS ingress, autoscaling, persistent storage, NetworkPolicies, GitOps manifests with ArgoCD, and captured evidence.
```

## 0:30 - 1:15 Runtime State

Show:

```bash
kubectl get pods -n users-api -o wide
kubectl get ingress -n users-api
curl -k --resolve users-api.local:443:127.0.0.1 https://users-api.local/readyz
```

Point out:

- API Pods are ready.
- PostgreSQL is ready.
- HTTPS route returns a successful readiness response.

## 1:15 - 2:00 Platform Features

Show:

```bash
helm list -n users-api
kubectl get hpa -n users-api
kubectl get pvc -n users-api
kubectl get networkpolicy -n users-api
```

Point out:

- Helm owns the app release.
- HPA is configured.
- PostgreSQL data is persistent.
- NetworkPolicies define traffic boundaries.

## 2:00 - 3:00 GitOps

Show:

```bash
kubectl get applications -n argocd
```

Then open:

```text
argocd/applications/users-api-dev.yaml
argocd/applications/users-api-staging.yaml
argocd/app-of-apps/cloud-native-platform.yaml
```

Point out:

- dev and staging are separate Applications.
- both use automated sync, self-heal, and prune.
- the app-of-apps pattern lets ArgoCD discover child Applications from Git.

If ArgoCD image pulls are blocked locally, call it out as an environment issue and show `docs/argocd-troubleshooting.md`.

## 3:00 - 4:00 Evidence

Show:

```text
docs/evidence.md
docs/screenshots/
```

Point out that the repo includes raw command output and screenshots so a reviewer does not need to trust your machine.

## 4:00 - 5:00 Wrap-Up

Say:

```text
The main design goal was to show operational ownership: not just Kubernetes YAML, but packaging, rollout behavior, storage, network boundaries, GitOps desired state, troubleshooting, and evidence.
```
