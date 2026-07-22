# Cloud Native Kubernetes Platform

## Overview

This repository demonstrates a production-style Kubernetes platform for deploying and operating a cloud-native Go API.

The project is built incrementally. Phase 1 established the Kubernetes foundation. Phase 2 adds platform features that make the deployment more realistic: Ingress, HTTPS, Helm packaging, autoscaling, and rolling updates.

## Current Status

Phase 2: Professional Kubernetes platform features.

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

## Platform Features

- Ingress-based external access
- TLS termination
- Helm-based application packaging
- Horizontal Pod Autoscaling
- Rolling updates and rollback
- Environment-specific values

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
│   └── screenshots/
├── kind/
│   └── cluster-config.yaml
├── k8s/
│   ├── namespaces/
│   ├── configmaps/
│   ├── secrets/
│   ├── ingress/
│   ├── tls/
│   └── hpa/
├── apps/
│   └── users-api/
│       └── manifests/
├── helm/
│   └── users-api/
└── scripts/
```

## Roadmap

- Phase 3: Network Policies and persistent storage
- Phase 4: GitOps with ArgoCD
- Phase 5: Observability evidence and professional presentation

## Project Status

This project is under active development.
