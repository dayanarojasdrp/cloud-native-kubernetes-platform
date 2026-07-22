# Local TLS

Phase 2 uses a self-signed certificate for `users-api.local`.

Generate and apply the local TLS Secret with:

```bash
./scripts/generate-local-tls.sh
```

The generated certificate and private key are intentionally ignored by Git:

```text
k8s/tls/users-api.local.crt
k8s/tls/users-api.local.key
```

The Kubernetes Secret created by the script is named:

```text
users-api-tls
```

In a real production environment, TLS certificates should be issued and rotated by a trusted certificate authority, normally through an automated mechanism such as cert-manager.
