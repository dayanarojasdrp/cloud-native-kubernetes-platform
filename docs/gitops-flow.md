# GitOps Flow

Phase 4 adds ArgoCD as the GitOps controller for the Users API platform.

## Flow

1. Developer changes Helm values or Kubernetes manifests.
2. Change is committed to GitHub.
3. ArgoCD detects drift between Git and the live cluster.
4. ArgoCD syncs the desired state.
5. Kubernetes updates the workload.
6. Rollout is verified.

## Repository Layout

```text
argocd/
├── applications/
│   ├── users-api-dev.yaml
│   └── users-api-staging.yaml
├── app-of-apps/
│   └── cloud-native-platform.yaml
└── environments/
    ├── dev/
    └── staging/
```

## App Of Apps

The root Application is:

```text
argocd/app-of-apps/cloud-native-platform.yaml
```

It points ArgoCD to:

```text
argocd/applications/
```

That directory contains the child Applications for each environment.

## Environment Applications

The platform defines two GitOps-managed environments:

```text
users-api-dev
  -> Helm release: users-api-dev
  -> Host: users-api.dev.local
  -> Min replicas: 1
  -> Max replicas: 3
  -> APP_ENV: development

users-api-staging
  -> Helm release: users-api-staging
  -> Host: users-api.staging.local
  -> Min replicas: 2
  -> Max replicas: 5
  -> APP_ENV: staging
```

Both Applications render the same Helm chart from:

```text
helm/users-api
```

## Automated Sync

Each users-api Application enables:

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

This means:

- ArgoCD applies committed Git changes automatically.
- Resources removed from Git are pruned from the cluster.
- Manual drift in the cluster is corrected back to Git.

## Local Platform Scope

For this phase, ArgoCD manages the API releases through Helm. The existing local platform foundation still provides:

- PostgreSQL Service and Deployment
- database Secret
- local TLS Secret
- ingress-nginx controller

This avoids committing real credentials or private TLS keys to Git. In production, secrets should be handled by a dedicated secrets workflow such as External Secrets, Sealed Secrets, or a cloud secret manager integration.

## Validation

Install ArgoCD:

```bash
./scripts/install-argocd.sh
```

Apply the root app-of-apps:

```bash
./scripts/apply-argocd-apps.sh
```

Validate the GitOps-managed environments:

```bash
./scripts/validate-gitops.sh
```

Inspect ArgoCD status:

```bash
kubectl get applications -n argocd
kubectl describe application users-api-dev -n argocd
kubectl describe application users-api-staging -n argocd
```

Test the HTTPS routes:

```bash
curl -k --resolve users-api.dev.local:443:127.0.0.1 https://users-api.dev.local/readyz
curl -k --resolve users-api.staging.local:443:127.0.0.1 https://users-api.staging.local/readyz
```
