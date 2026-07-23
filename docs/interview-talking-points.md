# Interview Talking Points

## Project Summary

This repository demonstrates a production-style Kubernetes platform around a Go Users API. It starts with a local Kind cluster, then layers in Helm packaging, HTTPS ingress, autoscaling, persistent storage, network security boundaries, and GitOps delivery with ArgoCD manifests.

## What I Built

- Reproducible local Kubernetes cluster with Kind.
- Users API Deployment, Service, ConfigMap, Secret integration, probes, and resource limits.
- PostgreSQL backing service with persistent storage.
- Ingress-based HTTPS access through ingress-nginx.
- Helm chart with dev and staging values.
- HPA for API scaling.
- NetworkPolicies for default-deny and explicit traffic allows.
- ArgoCD Application manifests for dev and staging.
- App-of-apps GitOps structure.
- Evidence screenshots and repeatable capture scripts.

## Design Decisions

- Helm owns the application release because it keeps Kubernetes templates reusable across environments.
- ArgoCD owns the desired state for dev and staging because Git should become the deployment source of truth.
- Secrets and local TLS keys are intentionally not committed.
- NetworkPolicies use clear labels so the intended traffic path is auditable.
- PostgreSQL remains local for this platform repo, but the persistence pattern maps to managed storage in a cloud environment.

## Tradeoffs

- Kind is excellent for local reproducibility, but its default CNI does not enforce NetworkPolicies.
- The local database is shared by the demo environments; production should isolate credentials and storage.
- ArgoCD image pulls can be blocked by registry/network conditions in local Docker Desktop setups, so the repo includes a preload script and troubleshooting guide.

## How I Would Extend It

- Add External Secrets or Sealed Secrets for GitOps-safe secret management.
- Split dev and staging into separate namespaces or clusters.
- Add kube-prometheus-stack or connect this app to a dedicated observability repo.
- Add CI that runs Helm lint, template rendering, and policy checks.
- Add release promotion from dev to staging through pull requests.
