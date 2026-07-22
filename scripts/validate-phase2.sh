#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="users-api"
INGRESS_HOSTNAME="${INGRESS_HOSTNAME:-users-api.local}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

echo "Validating Helm release..."
helm status users-api --namespace "${NAMESPACE}" >/dev/null

echo "Validating users-api rollout..."
kubectl rollout status deployment/users-api --namespace "${NAMESPACE}" --timeout=180s

echo
echo "Ingress:"
kubectl get ingress --namespace "${NAMESPACE}"

echo
echo "HPA:"
kubectl get hpa --namespace "${NAMESPACE}"

echo
echo "Testing HTTPS health endpoint through Ingress..."
curl \
  --fail \
  --silent \
  --show-error \
  --insecure \
  --noproxy "*" \
  --resolve "${INGRESS_HOSTNAME}:443:127.0.0.1" \
  "https://${INGRESS_HOSTNAME}/healthz"

echo
echo
echo "Testing HTTPS readiness endpoint through Ingress..."
curl \
  --fail \
  --silent \
  --show-error \
  --insecure \
  --noproxy "*" \
  --resolve "${INGRESS_HOSTNAME}:443:127.0.0.1" \
  "https://${INGRESS_HOSTNAME}/readyz"

echo
echo
echo "Phase 2 validation completed successfully."
