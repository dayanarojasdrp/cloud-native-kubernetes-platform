#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-cloud-native-platform}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.10.7}"
DEX_VERSION="${DEX_VERSION:-v2.37.0}"
REDIS_VERSION="${REDIS_VERSION:-7.0.14-alpine}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

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
  if ! kind load docker-image "${image}" --name "${CLUSTER_NAME}"; then
    echo "kind load failed for ${image}; falling back to direct containerd import."
    platform="$(docker image inspect "${image}" --format '{{.Os}}/{{.Architecture}}')"

    for node in $(kind get nodes --name "${CLUSTER_NAME}"); do
      echo "Importing ${image} into ${node}..."
      docker save "${image}" \
        | docker exec --privileged -i "${node}" \
          ctr --namespace=k8s.io images import \
            --platform "${platform}" \
            --digests \
            --snapshotter=overlayfs \
            -
    done
  fi
done

echo
echo "ArgoCD images are available in Kind."
