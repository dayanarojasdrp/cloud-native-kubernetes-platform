# Cloud Native Kubernetes Platform

## Overview

This repository demonstrates a production-style Kubernetes platform for deploying and operating a cloud-native Go API.

The project is built incrementally. Phase 1 established the Kubernetes foundation. Phase 2 added platform features such as Ingress, HTTPS, Helm packaging, autoscaling, and rolling updates. Phase 3 added persistent storage and network security boundaries. Phase 4 added GitOps delivery with ArgoCD. Phase 5 adds evidence, troubleshooting, and professional presentation material.

## Current Status

Phase 5: Evidence and professional presentation for a production-style Kubernetes platform.

Fast review:

- Architecture diagram: `docs/screenshots/01-architecture.png`
- Evidence index: `docs/evidence.md`
- Demo script: `docs/demo-script.md`
- Demo video outline: `docs/demo-video-outline.md`
- Interview talking points: `docs/interview-talking-points.md`
- Observability notes: `docs/observability.md`
- Troubleshooting guide: `docs/troubleshooting.md`

## What This Project Demonstrates

- Kubernetes application deployment
- ConfigMaps and Secrets
- Health checks
- Resource management
- Service discovery
- Local reproducible cluster
- Ingress-based external access
- TLS termination
- Helm-based application packaging
- Horizontal Pod Autoscaling
- Rolling updates and rollback
- Environment-specific values
- Persistent storage with PVCs
- NetworkPolicy-based traffic restrictions
- Security documentation and validation evidence
- GitOps delivery with ArgoCD
- Automated sync, pruning, and self-healing
- Dev and staging GitOps Applications
- Evidence screenshots and raw command output
- Demo and interview-ready documentation

## Platform Features

- Ingress-based external access
- TLS termination
- Helm-based application packaging
- Horizontal Pod Autoscaling
- Rolling updates and rollback
- Environment-specific values
- PostgreSQL PersistentVolumeClaim
- Default-deny ingress NetworkPolicies
- Explicit ingress-to-api and api-to-database traffic rules
- ArgoCD app-of-apps workflow
- Git-driven Helm releases for dev and staging
- Automated drift correction through self-heal
- Repeatable evidence capture workflow
- Recruiter-friendly project walkthrough

## Application

The workload used by this platform is:

`users-api-cloud-native-go`

Local API repository path used by the helper script:

`/Users/harrydouglass/Documents/proyect_go`

## Current Architecture

See `docs/architecture.md`.

## Quick Start

Create or recreate the local Kind cluster:

```bash
./scripts/setup-kind.sh
```

If an older Phase 1 cluster already exists and does not expose ports 80 and 443, recreate it with:

```bash
RESET_CLUSTER=true ./scripts/setup-kind.sh
```

Build the API image and load it into Kind:

```bash
./scripts/build-and-load-image.sh
```

Apply the namespace, PostgreSQL configuration, local database Secret, and temporary PostgreSQL database:

```bash
kubectl apply -f k8s/namespaces/users-api.yaml
kubectl apply -f k8s/configmaps/postgres-initdb-configmap.yaml
kubectl apply -f k8s/secrets/database-credentials.local.yaml
kubectl apply -f k8s/storage/postgres-pvc.yaml
kubectl apply -f apps/users-api/manifests/postgres.yaml
kubectl rollout status deployment/postgres -n users-api
```

Install ingress-nginx:

```bash
./scripts/install-ingress.sh
```

Generate and apply the local TLS Secret:

```bash
./scripts/generate-local-tls.sh
```

Deploy the Users API with Helm:

```bash
./scripts/deploy-helm.sh
```

Validate Phase 2:

```bash
./scripts/validate-phase2.sh
```

Apply Phase 3 security and storage resources:

```bash
kubectl apply -f k8s/storage/postgres-pvc.yaml
kubectl apply -f k8s/network-policies/
```

Validate Phase 3:

```bash
./scripts/validate-phase3.sh
```

Install ArgoCD:

```bash
./scripts/install-argocd.sh
```

If the local cluster hits registry timeouts while pulling ArgoCD images, preload them into Kind and rerun the installer:

```bash
./scripts/preload-argocd-images.sh
./scripts/install-argocd.sh
```

Apply the GitOps root Application:

```bash
./scripts/apply-argocd-apps.sh
```

Validate Phase 4:

```bash
./scripts/validate-gitops.sh
```

Capture Phase 5 evidence:

```bash
./scripts/capture-evidence.sh
```

The script writes PNG screenshots to `docs/screenshots/` and raw command output to `docs/evidence/`.

## Evidence

The mandatory evidence screenshots are:

```text
docs/screenshots/01-architecture.png
docs/screenshots/02-pods-running.png
docs/screenshots/03-ingress-https.png
docs/screenshots/04-helm-release.png
docs/screenshots/05-hpa.png
docs/screenshots/06-network-policies.png
docs/screenshots/07-pvc.png
docs/screenshots/08-argocd-synced.png
docs/screenshots/09-rolling-update.png
```

See `docs/evidence.md` for the evidence index and current validation notes.

## Helm Deployment

Install or upgrade the development environment:

```bash
helm upgrade --install users-api ./helm/users-api \
  --namespace users-api \
  --create-namespace \
  -f helm/users-api/values-dev.yaml
```

Install or upgrade the staging environment values:

```bash
helm upgrade --install users-api ./helm/users-api \
  --namespace users-api \
  --create-namespace \
  -f helm/users-api/values-staging.yaml
```

## Ingress and TLS

Phase 2 exposes the API through:

```text
https://users-api.local
```

For command-line validation without editing `/etc/hosts`, use:

```bash
curl -k --resolve users-api.local:443:127.0.0.1 https://users-api.local/healthz
curl -k --resolve users-api.local:443:127.0.0.1 https://users-api.local/readyz
```

To open it in a browser, add this entry to `/etc/hosts`:

```text
127.0.0.1 users-api.local
```

The local certificate is self-signed, so the browser will show a local trust warning.

## Autoscaling

The Helm chart creates an HPA:

```text
minReplicas: 2
maxReplicas: 5
targetCPUUtilizationPercentage: 70
```

Inspect it with:

```bash
kubectl get hpa -n users-api
kubectl describe hpa users-api -n users-api
```

On a minimal Kind cluster without metrics-server, the HPA target can appear as `<unknown>`. The HPA object is still created and bound to the Deployment; installing metrics-server would provide live CPU utilization.

## Network Policies

Phase 3 adds NetworkPolicies in `k8s/network-policies/`.

The intended traffic model is:

```text
ingress-nginx -> users-api -> postgres
```

The namespace starts from a default-deny ingress posture, then explicitly allows:

- ingress-nginx controller traffic to the API on port `8080`
- Users API Pod traffic to PostgreSQL on port `5432`

Kind's default `kindnet` CNI does not enforce NetworkPolicies. The policy manifests are valid and applied, but packet-level blocking requires a NetworkPolicy-aware CNI such as Calico or Cilium.

## Persistent Storage

Phase 3 replaces PostgreSQL temporary `emptyDir` storage with a PersistentVolumeClaim:

```text
postgres-data
```

In the local Kind cluster, the default `standard` StorageClass uses the local-path provisioner. The Phase 3 validation script creates a user, restarts the PostgreSQL Pod, and confirms the data remains available.

## Security Documentation

See `docs/security.md`.

## GitOps with ArgoCD

Phase 4 introduces ArgoCD as the GitOps controller.

The desired state lives in Git:

```text
argocd/app-of-apps/cloud-native-platform.yaml
argocd/applications/users-api-dev.yaml
argocd/applications/users-api-staging.yaml
```

The root app-of-apps points ArgoCD at `argocd/applications/`. ArgoCD then creates and reconciles the `users-api-dev` and `users-api-staging` Applications.

Both environment Applications deploy the same Helm chart from:

```text
helm/users-api
```

Environment differences are defined through Helm values in each ArgoCD Application:

- `users-api-dev`: `users-api.dev.local`, 1-3 replicas, development config
- `users-api-staging`: `users-api.staging.local`, 2-5 replicas, staging config

Each Application enables:

- automated sync
- prune
- self-heal

See `docs/gitops-flow.md`.

For local ArgoCD installation troubleshooting, see `docs/argocd-troubleshooting.md`.

The latest local capture shows the root app-of-apps, dev Application, and staging Application in `Synced` and `Healthy` state.

## Rolling Updates

Run the rolling update demo:

```bash
./scripts/demo-rolling-update.sh
```

Useful commands:

```bash
kubectl rollout status deployment/users-api -n users-api
kubectl rollout history deployment/users-api -n users-api
kubectl rollout undo deployment/users-api -n users-api
```

## Repository Structure

```text
cloud-native-kubernetes-platform/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── argocd-troubleshooting.md
│   ├── demo-video-outline.md
│   ├── demo-script.md
│   ├── evidence.md
│   ├── evidence/
│   ├── gitops-flow.md
│   ├── interview-talking-points.md
│   ├── observability.md
│   ├── troubleshooting.md
│   └── screenshots/
├── argocd/
│   ├── applications/
│   ├── app-of-apps/
│   └── environments/
├── kind/
│   └── cluster-config.yaml
├── k8s/
│   ├── namespaces/
│   ├── configmaps/
│   ├── secrets/
│   ├── ingress/
│   ├── tls/
│   ├── hpa/
│   ├── storage/
│   └── network-policies/
├── apps/
│   └── users-api/
│       └── manifests/
├── helm/
│   └── users-api/
└── scripts/
```

## Roadmap

- Connect this platform to a dedicated observability stack or add kube-prometheus-stack.
- Add GitHub Actions for Helm lint, template rendering, and policy validation.
- Add GitOps-safe secret management with External Secrets or Sealed Secrets.

## Project Status

This project is interview-ready as a local Kubernetes platform portfolio project.
