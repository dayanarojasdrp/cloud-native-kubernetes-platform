# Staging Environment

The staging environment is managed by the `users-api-staging` ArgoCD Application.

Key differences:

- Helm release: `users-api-staging`
- Ingress host: `users-api.staging.local`
- Minimum replicas: `2`
- Maximum replicas: `5`
- Application environment: `staging`
- Log level: `info`

The local Kubernetes foundation still provides the shared PostgreSQL Service, database Secret, and local TLS Secret. In a production platform, staging would normally use its own database credentials, TLS certificate, and isolated namespace or cluster.
