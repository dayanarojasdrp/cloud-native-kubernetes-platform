# Platform Architecture

This project builds a local production-style Kubernetes platform around the Users API.

## Phase 4 Architecture

```text
                         macOS Host
                              |
        https://users-api.local / dev.local / staging.local
                              |
                              v
                    Kind extraPortMappings
                         80 / 443
                              |
                              v
                    ingress-nginx Controller
                              |
                       TLS termination
                              |
                              v
                   users-api Ingress resources
                              |
                              v
                    users-api Services
                       ClusterIP :80
                              |
                              v
               Users API Deployments managed by ArgoCD
                     Helm release: users-api
                     Helm release: users-api-dev
                     Helm release: users-api-staging
                         NetworkPolicy: only ingress-nginx inbound
                              |
                              | DB_URL from Secret
                              v
                       postgres Service
                       ClusterIP :5432
                       NetworkPolicy: only users-api inbound
                              |
                              v
                    PostgreSQL Deployment
                    PersistentVolumeClaim
                    postgres-data
```

## GitOps Control Loop

```text
GitHub repository
  -> argocd/app-of-apps/cloud-native-platform.yaml
  -> ArgoCD root Application
  -> argocd/applications/users-api-dev.yaml
  -> argocd/applications/users-api-staging.yaml
  -> Helm chart rendering from helm/users-api
  -> Kubernetes desired state applied to the cluster
```

ArgoCD continuously compares the desired state in Git with the live Kubernetes state. When a difference appears, automated sync and self-heal bring the cluster back to the committed configuration.

## Request Flow

```text
Client
  -> HTTPS request to users-api.local, users-api.dev.local, or users-api.staging.local
  -> Kind maps host port 443 to the control-plane node
  -> ingress-nginx receives the request
  -> Ingress rule matches the requested host
  -> TLS is terminated with the users-api-tls Secret
  -> Traffic is forwarded to the matching users-api Service
  -> The Service routes to ready users-api Pods
```

## Helm Packaging

The Users API is packaged as a Helm chart in `helm/users-api`.

The chart manages:

- ConfigMap
- Deployment
- Service
- Ingress
- HorizontalPodAutoscaler

Environment-specific values live in:

- `helm/users-api/values-dev.yaml`
- `helm/users-api/values-staging.yaml`

GitOps environment values are also embedded in:

- `argocd/applications/users-api-dev.yaml`
- `argocd/applications/users-api-staging.yaml`

This keeps the ArgoCD Applications self-contained for the local demo while still using the same reusable Helm chart.

## TLS

Phase 2 uses a local self-signed certificate for `users-api.local`.

The generated certificate and key are not committed to Git. The Kubernetes TLS Secret is named:

```text
users-api-tls
```

## Autoscaling

The HPA targets the `users-api` Deployment:

```text
minReplicas: 2
maxReplicas: 5
targetCPUUtilizationPercentage: 70
```

The HPA can be inspected with:

```bash
kubectl get hpa -n users-api
kubectl describe hpa users-api -n users-api
```

## Rolling Updates

The Deployment uses a rolling update strategy:

```text
maxUnavailable: 0
maxSurge: 1
revisionHistoryLimit: 5
```

This allows the image tag to be updated while Kubernetes keeps serving traffic through ready Pods.

## Persistent Storage

PostgreSQL uses a PersistentVolumeClaim named `postgres-data`.

In the local Kind cluster, the default `standard` StorageClass dynamically provisions a local PersistentVolume. This demonstrates PVC binding and data survival across PostgreSQL Pod restarts.

## Network Security

Phase 3 adds NetworkPolicies in the `users-api` namespace.

```text
default-deny-ingress
  -> denies inbound traffic unless another policy allows it

allow-ingress-to-api-from-ingress-controller
  -> ingress-nginx controller can reach users-api Pods on TCP 8080

allow-api-to-db
  -> users-api Pods can reach PostgreSQL on TCP 5432

deny-direct-db-access-from-other-namespaces
  -> documents the database deny-by-default boundary
```

The local cluster currently uses `kindnet`, which does not enforce NetworkPolicies. The policies are still applied as valid Kubernetes resources, and enforcement can be tested by recreating the cluster with Calico or Cilium.

## GitOps Environments

Phase 4 creates two GitOps-managed API environments:

```text
users-api-dev
  -> host: users-api.dev.local
  -> min replicas: 1
  -> max replicas: 3

users-api-staging
  -> host: users-api.staging.local
  -> min replicas: 2
  -> max replicas: 5
```

For this local platform phase, both environments reuse the existing local PostgreSQL Service, database Secret, and self-signed TLS Secret in the `users-api` namespace. In a real production setup, each environment would normally receive isolated credentials, certificates, and either separate namespaces or separate clusters.
