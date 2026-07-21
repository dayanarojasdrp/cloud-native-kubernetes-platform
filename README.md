# Cloud Native Kubernetes Platform

## Overview

This repository demonstrates how to deploy and operate a cloud-native Go API on Kubernetes using modern DevOps practices.

The platform is built incrementally. Phase 1 focuses on a reproducible local Kubernetes cluster and a clean application deployment using native Kubernetes resources.

## Current Status

Phase 1: Kubernetes foundation and basic application deployment.

## What This Project Demonstrates

- Kubernetes application deployment
- ConfigMaps and Secrets
- Health checks
- Resource management
- Service discovery
- Local reproducible cluster

## Phase 1 Components

- Kind local Kubernetes cluster
- Dedicated namespace
- Users API Deployment
- Internal ClusterIP Service
- PostgreSQL development database
- ConfigMap-based application configuration
- Secret-based database configuration
- Liveness and readiness probes
- CPU and memory requests and limits

## Application

The workload used by this platform is:

`users-api-cloud-native-go`

Local API repository path used by the helper script:

`/Users/harrydouglass/Documents/proyect_go`

## Current Architecture

See `docs/architecture.md`.

## Quick Start

Create the local Kind cluster:

```bash
./scripts/setup-kind.sh
```

Build the API image and load it into Kind:

```bash
./scripts/build-and-load-image.sh
```

Apply the Phase 1 resources:

```bash
kubectl apply -f k8s/namespaces/users-api.yaml
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/database-credentials.local.yaml
kubectl apply -f apps/users-api/manifests/postgres.yaml
kubectl apply -f apps/users-api/manifests/deployment.yaml
kubectl apply -f apps/users-api/manifests/service.yaml
```

Validate the deployment:

```bash
./scripts/validate.sh
```

## Local API Access

Phase 1 uses temporary port-forwarding:

```bash
kubectl port-forward service/users-api 8080:80 -n users-api
```

Then test:

```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/users
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
│   └── secrets/
├── apps/
│   └── users-api/
│       └── manifests/
└── scripts/
```

## Roadmap

- Phase 2: Ingress, local TLS, Helm, HPA, and rolling updates
- Phase 3: Network Policies and persistent storage
- Phase 4: GitOps with ArgoCD
- Phase 5: Observability evidence and professional presentation

## Project Status

This project is under active development.
