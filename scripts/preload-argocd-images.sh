#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-cloud-native-platform}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.10.7}"
DEX_VERSION="${DEX_VERSION:-v2.37.0}"
REDIS_VERSION="${REDIS_VERSION:-7.0.14-alpine}"

IMAGES=(
  "quay.io/argoproj/argocd:${ARGOCD_VERSION}"
  "ghcr.io/dexidp/dex:${DEX_VERSION}"
  "redis:${REDIS_VERSION}"
)

echo "Preloading ArgoCD images into Kind cluster '${CLUSTER_NAME}'..."

for image in "${IMAGES[@]}"; do
  echo
  echo "Pulling ${image}..."
  docker pull "${image}"

  echo "Loading ${image} into Kind..."
  kind load docker-image "${image}" --name "${CLUSTER_NAME}"
done

echo
echo "ArgoCD images are available in Kind."
