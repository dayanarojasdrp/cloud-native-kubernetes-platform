#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENSHOT_DIR="${PROJECT_ROOT}/docs/screenshots"
EVIDENCE_DIR="${PROJECT_ROOT}/docs/evidence"
RENDERER="${PROJECT_ROOT}/scripts/render-terminal-screenshot.py"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

mkdir -p "${SCREENSHOT_DIR}" "${EVIDENCE_DIR}"

capture() {
  local name="$1"
  local title="$2"
  local command="$3"
  local text_file="${EVIDENCE_DIR}/${name}.txt"
  local image_file="${SCREENSHOT_DIR}/${name}.png"

  echo "Capturing ${name}..."

  {
    echo "# ${title}"
    echo "# Command: ${command}"
    echo
    bash --noprofile --norc -c "cd '${PROJECT_ROOT}' && export PATH='${PROJECT_ROOT}/.bin':\"\${PATH}\" && ${command}"
  } > "${text_file}" 2>&1 || true

  python3 "${RENDERER}" \
    --title "${title}" \
    --command "${command}" \
    --input "${text_file}" \
    --output "${image_file}"
}

python3 "${RENDERER}" \
  --architecture \
  --output "${SCREENSHOT_DIR}/01-architecture.png"

capture "02-pods-running" "Pods Running" "kubectl get pods -n users-api -o wide"
capture "03-ingress-https" "Ingress HTTPS" "kubectl get ingress -n users-api && curl --fail --silent --show-error --insecure --noproxy '*' --resolve users-api.local:443:127.0.0.1 https://users-api.local/readyz"
capture "04-helm-release" "Helm Release" "helm list -n users-api"
capture "05-hpa" "Horizontal Pod Autoscaler" "kubectl get hpa -n users-api -o wide"
capture "06-network-policies" "Network Policies" "kubectl get networkpolicy -n users-api"
capture "07-pvc" "Persistent Volume Claim" "kubectl get pvc -n users-api -o wide"
capture "08-argocd-synced" "ArgoCD Applications - Controller Pending" "kubectl get applications -n argocd -o wide && kubectl get pods -n argocd"
capture "09-rolling-update" "Rolling Update" "kubectl rollout history deployment/users-api -n users-api && kubectl rollout status deployment/users-api -n users-api"

echo
echo "Evidence screenshots written to ${SCREENSHOT_DIR}"
echo "Raw command output written to ${EVIDENCE_DIR}"
