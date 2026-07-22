#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="users-api"
RELEASE_NAME="users-api"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

VALUES_FILE="${PROJECT_ROOT}/helm/users-api/values-${ENVIRONMENT}.yaml"

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "Error: values file not found: ${VALUES_FILE}"
  exit 1
fi

echo "Deploying ${RELEASE_NAME} with Helm values-${ENVIRONMENT}.yaml..."

helm upgrade --install "${RELEASE_NAME}" "${PROJECT_ROOT}/helm/users-api" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}"

echo
helm status "${RELEASE_NAME}" --namespace "${NAMESPACE}"
