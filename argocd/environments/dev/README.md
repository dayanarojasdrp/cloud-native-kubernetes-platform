# Dev Environment

The dev environment is managed by the `users-api-dev` ArgoCD Application.

Key differences:

- Helm release: `users-api-dev`
- Ingress host: `users-api.dev.local`
- Minimum replicas: `1`
- Maximum replicas: `3`
- Application environment: `development`
- Log level: `debug`

The local Kubernetes foundation still provides the shared PostgreSQL Service, database Secret, and local TLS Secret. In a production platform, those dependencies would be managed through a dedicated secrets workflow such as External Secrets or Sealed Secrets.
