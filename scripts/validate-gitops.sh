#!/usr/bin/env bash

set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
APP_NAMESPACE="${APP_NAMESPACE:-users-api}"
LOCAL_IP="${LOCAL_IP:-127.0.0.1}"
DEV_HOST="${DEV_HOST:-users-api.dev.local}"
STAGING_HOST="${STAGING_HOST:-users-api.staging.local}"

wait_for_application() {
  local app_name="$1"
  local attempts="${2:-60}"

  echo "Waiting for ArgoCD Application '${app_name}' to become Synced and Healthy..."

  for attempt in $(seq 1 "${attempts}"); do
    local sync_status
    local health_status

    sync_status="$(kubectl get application "${app_name}" \
      --namespace "${ARGOCD_NAMESPACE}" \
      -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"

    health_status="$(kubectl get application "${app_name}" \
      --namespace "${ARGOCD_NAMESPACE}" \
      -o jsonpath='{.status.health.status}' 2>/dev/null || true)"

    if [[ "${sync_status}" == "Synced" && "${health_status}" == "Healthy" ]]; then
      echo "${app_name}: Synced / Healthy"
      return 0
    fi

    if (( attempt == attempts )); then
      echo "Error: ${app_name} did not become Synced and Healthy."
      echo "Last status: sync='${sync_status:-unknown}' health='${health_status:-unknown}'"
      kubectl describe application "${app_name}" --namespace "${ARGOCD_NAMESPACE}" || true
      return 1
    fi

    sleep 5
  done
}

echo "Validating ArgoCD namespace..."
kubectl get namespace "${ARGOCD_NAMESPACE}" >/dev/null

echo "Validating ArgoCD Applications..."
kubectl get applications --namespace "${ARGOCD_NAMESPACE}"

wait_for_application cloud-native-platform
wait_for_application users-api-dev
wait_for_application users-api-staging

echo
echo "GitOps-managed workloads:"
kubectl get deployments,services,ingress,hpa \
  --namespace "${APP_NAMESPACE}" \
  --selector=app.kubernetes.io/instance=users-api-dev

kubectl get deployments,services,ingress,hpa \
  --namespace "${APP_NAMESPACE}" \
  --selector=app.kubernetes.io/instance=users-api-staging

echo
echo "Testing dev HTTPS route..."
curl \
  --fail \
  --silent \
  --show-error \
  --insecure \
  --noproxy "*" \
  --resolve "${DEV_HOST}:443:${LOCAL_IP}" \
  "https://${DEV_HOST}/readyz"

echo
echo
echo "Testing staging HTTPS route..."
curl \
  --fail \
  --silent \
  --show-error \
  --insecure \
  --noproxy "*" \
  --resolve "${STAGING_HOST}:443:${LOCAL_IP}" \
  "https://${STAGING_HOST}/readyz"

echo
echo
echo "GitOps validation completed successfully."
