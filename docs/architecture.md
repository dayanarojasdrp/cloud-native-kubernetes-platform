# Phase 1 Architecture

Phase 1 creates a local Kubernetes foundation for running the Users API with a temporary PostgreSQL database.

```text
                    macOS Host
                        |
                 kubectl port-forward
                        |
                        v
               users-api Service
                   ClusterIP:80
                        |
                        v
            users-api Deployment
                 2 API Pods
                        |
                        | DB_URL from Secret
                        v
                postgres Service
                 ClusterIP:5432
                        |
                        v
              PostgreSQL Deployment
                  1 Database Pod
                        |
                        v
            Temporary emptyDir Storage
```

## Kubernetes Components

```text
ConfigMap
   └── APP_ENV, PORT, LOG_LEVEL and HTTP timeout settings

Secret
   └── Database credentials and DB_URL

Liveness Probe
   └── /healthz

Readiness Probe
   └── /readyz
```

## Design Decisions

The API configuration is split between a ConfigMap and a Secret. Non-sensitive runtime values such as `APP_ENV`, `PORT`, `LOG_LEVEL`, and timeout settings live in the ConfigMap. Database credentials and the full `DB_URL` live in the Secret.

PostgreSQL uses `emptyDir` storage in this phase. This is intentionally temporary because Phase 1 focuses on basic Kubernetes deployment, health checks, resource management, and service discovery. Persistent storage will be added later.

The Users API is exposed only through an internal ClusterIP Service. Local access is provided with `kubectl port-forward` until Ingress and TLS are introduced in Phase 2.
