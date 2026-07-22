#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="users-api"
RELEASE_NAME="users-api"
IMAGE_TAG="${IMAGE_TAG:-phase2-v2}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

echo "Building and loading ${IMAGE_TAG}..."
IMAGE_TAG="${IMAGE_TAG}" "${PROJECT_ROOT}/scripts/build-and-load-image.sh"

echo
echo "Upgrading Helm release to ${IMAGE_TAG}..."
helm upgrade "${RELEASE_NAME}" "${PROJECT_ROOT}/helm/users-api" \
  --namespace "${NAMESPACE}" \
  --values "${PROJECT_ROOT}/helm/users-api/values-dev.yaml" \
  --set "image.tag=${IMAGE_TAG}"

kubectl rollout status deployment/users-api --namespace "${NAMESPACE}" --timeout=180s

echo
echo "Rollout history:"
kubectl rollout history deployment/users-api --namespace "${NAMESPACE}"

echo
echo "Rolling back to chart default image tag..."
helm upgrade "${RELEASE_NAME}" "${PROJECT_ROOT}/helm/users-api" \
  --namespace "${NAMESPACE}" \
  --values "${PROJECT_ROOT}/helm/users-api/values-dev.yaml"

kubectl rollout status deployment/users-api --namespace "${NAMESPACE}" --timeout=180s

echo
echo "Rolling update demo completed successfully."
