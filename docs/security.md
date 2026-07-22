# Security Decisions

Phase 3 adds the first security-focused platform layer: persistent storage for PostgreSQL and NetworkPolicy definitions that describe the intended traffic boundaries.

## Why Secrets Are Separated From ConfigMaps

ConfigMaps hold non-sensitive runtime configuration such as `APP_ENV`, `PORT`, `LOG_LEVEL`, and timeout settings.

Secrets hold sensitive database values:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `DB_URL`

This keeps credentials out of general configuration files and makes it clear which values require tighter handling. A Kubernetes Secret is not a reason to publish credentials publicly; local secret files remain ignored by Git.

## Why Default-Deny NetworkPolicies Are Used

The namespace uses a default-deny ingress policy so Pods do not accept inbound traffic by default.

This changes the model from:

```text
Everything can talk to everything unless blocked.
```

to:

```text
Nothing receives traffic unless explicitly allowed.
```

That is a safer platform baseline and makes intended traffic easier to review.

## Which Traffic Is Allowed And Why

Allowed traffic in Phase 3:

```text
ingress-nginx controller
  -> users-api Pods
  -> TCP 8080
```

This allows external HTTPS requests to reach the API through the Ingress Controller.

```text
users-api Pods
  -> postgres Pod
  -> TCP 5432
```

This allows the API to connect to the database using `DB_URL` from the Secret.

Denied by default:

- Direct database access from other namespaces
- Random Pods in the `users-api` namespace reaching PostgreSQL
- Inbound traffic to application Pods unless another policy allows it

These policies rely on Kubernetes labels. In a production cluster, label mutation should be controlled with admission policies and workload identity should be considered for stronger guarantees.

## Persistent Storage Decision

PostgreSQL now uses a PersistentVolumeClaim named `postgres-data`.

In the local Kind cluster, the default `standard` StorageClass is backed by the local-path provisioner. This is enough to demonstrate:

- PVC creation
- PV binding
- Database data surviving a PostgreSQL Pod restart
- Separation between application config and database credentials

## Local NetworkPolicy Enforcement Note

The current local Kind cluster uses `kindnet`. It accepts NetworkPolicy resources, but it does not enforce packet-level policy decisions.

The manifests are still valid and document the intended security model. For a local enforcement demo, the cluster should be recreated with a NetworkPolicy-aware CNI such as Calico or Cilium.

## What Would Be Improved In Production

- Use a managed or highly available PostgreSQL service.
- Use encrypted volumes and backup policies.
- Use external secret management instead of local Secret manifests.
- Enable a NetworkPolicy-aware CNI in every environment.
- Add egress policies, not only ingress policies.
- Use cert-manager or a cloud certificate manager for TLS rotation.
- Add audit logging and policy-as-code checks in CI.
