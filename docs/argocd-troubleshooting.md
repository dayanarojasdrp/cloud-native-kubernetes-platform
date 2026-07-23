# ArgoCD Troubleshooting

## Image Pull Failures

When installing ArgoCD in a local Kind cluster, image pulls can fail because the local network or container registry temporarily rejects requests.

Common symptoms:

```text
ImagePullBackOff
ErrImagePull
TLS handshake timeout
connection refused
pull QPS exceeded
```

The platform includes a helper script to preload the ArgoCD images into the Kind node:

```bash
./scripts/preload-argocd-images.sh
```

Then rerun the installer:

```bash
./scripts/install-argocd.sh
```

## CRD Annotation Limit

Large ArgoCD CRDs can fail with client-side apply because of the `kubectl.kubernetes.io/last-applied-configuration` annotation size limit.

The installer uses server-side apply to avoid that issue:

```bash
kubectl apply --server-side --force-conflicts
```

## Version Pinning

The installer pins ArgoCD by default:

```text
v2.10.7
```

Pinning avoids unexpected behavior from a floating `stable` manifest. To test another version:

```bash
ARGOCD_VERSION=v3.4.2 ./scripts/install-argocd.sh
```
