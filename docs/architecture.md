# Platform Architecture

This project builds a local production-style Kubernetes platform around the Users API.

## Phase 2 Architecture

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
                              |
                              | DB_URL from Secret
                              v
                       postgres Service
                       ClusterIP :5432
                              |
                              v
                    PostgreSQL Deployment
                    temporary emptyDir storage
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

## Phase 1 Foundation Still Present

PostgreSQL remains intentionally temporary in Phase 2. It still uses `emptyDir` storage because persistent storage is reserved for Phase 3.
