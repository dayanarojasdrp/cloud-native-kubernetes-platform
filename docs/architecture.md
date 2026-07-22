# Platform Architecture

This project builds a local production-style Kubernetes platform around the Users API.

## Phase 3 Architecture

```text
                         macOS Host
                              |
                       https://users-api.local
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
                      users-api Ingress
                              |
                              v
                    users-api Service
                       ClusterIP :80
                              |
                              v
                 users-api Deployment managed by Helm
                         2 API Pods
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

## Request Flow

```text
Client
  -> HTTPS request to users-api.local
  -> Kind maps host port 443 to the control-plane node
  -> ingress-nginx receives the request
  -> Ingress rule matches users-api.local
  -> TLS is terminated with the users-api-tls Secret
  -> Traffic is forwarded to the users-api Service
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
