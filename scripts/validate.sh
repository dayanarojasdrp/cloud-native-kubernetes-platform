#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="users-api"
LOCAL_PORT="${LOCAL_PORT:-8080}"

echo "Validating namespace..."
kubectl get namespace "${NAMESPACE}" >/dev/null

echo "Validating PostgreSQL deployment..."
kubectl rollout status \
  deployment/postgres \
  --namespace "${NAMESPACE}" \
  --timeout=180s

echo "Validating users-api deployment..."
kubectl rollout status \
  deployment/users-api \
  --namespace "${NAMESPACE}" \
  --timeout=180s

echo
echo "Pods:"
kubectl get pods --namespace "${NAMESPACE}" -o wide

echo
echo "Services:"
kubectl get services --namespace "${NAMESPACE}"

echo
echo "ConfigMaps:"
kubectl get configmaps --namespace "${NAMESPACE}"

echo
echo "Secrets:"
kubectl get secrets --namespace "${NAMESPACE}"

echo
echo "Starting temporary port-forward..."

kubectl port-forward \
  service/users-api \
  "${LOCAL_PORT}:80" \
  --namespace "${NAMESPACE}" \
  >/tmp/users-api-port-forward.log 2>&1 &

PORT_FORWARD_PID=$!

cleanup() {
  if kill -0 "${PORT_FORWARD_PID}" >/dev/null 2>&1; then
    kill "${PORT_FORWARD_PID}" >/dev/null 2>&1 || true
    wait "${PORT_FORWARD_PID}" 2>/dev/null || true
  fi

  rm -f /tmp/users-api-port-forward.log
}

trap cleanup EXIT

for attempt in {1..15}; do
  if curl \
    --fail \
    --silent \
    "http://127.0.0.1:${LOCAL_PORT}/healthz" \
    >/dev/null; then
    break
  fi

  sleep 1
done

echo
echo "Testing liveness endpoint..."

curl \
  --fail \
  --silent \
  --show-error \
  "http://127.0.0.1:${LOCAL_PORT}/healthz"

echo
echo
echo "Testing readiness endpoint..."

curl \
  --fail \
  --silent \
  --show-error \
  "http://127.0.0.1:${LOCAL_PORT}/readyz"

echo
echo
echo "Phase 1 validation completed successfully."
