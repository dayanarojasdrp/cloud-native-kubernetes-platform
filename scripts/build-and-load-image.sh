#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="cloud-native-platform"
IMAGE_NAME="users-api"
IMAGE_TAG="${IMAGE_TAG:-phase1-v1}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_API_REPOSITORY="${PROJECT_ROOT}/../proyect_go"
API_REPOSITORY="${API_REPOSITORY:-${DEFAULT_API_REPOSITORY}}"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

if [[ ! -f "${API_REPOSITORY}/Dockerfile" ]]; then
  echo "Error: users-api repository was not found at:"
  echo "${API_REPOSITORY}"
  echo
  echo "Set API_REPOSITORY=/path/to/users-api-cloud-native-go and try again."
  exit 1
fi

if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Error: Kind cluster '${CLUSTER_NAME}' does not exist."
  echo "Run ./scripts/setup-kind.sh first."
  exit 1
fi

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."

docker build \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  "${API_REPOSITORY}"

echo "Loading image into Kind..."

kind load docker-image \
  "${IMAGE_NAME}:${IMAGE_TAG}" \
  --name "${CLUSTER_NAME}"

echo
echo "Image loaded successfully:"
echo "${IMAGE_NAME}:${IMAGE_TAG}"
