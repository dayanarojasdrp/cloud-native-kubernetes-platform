#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

echo "Applying GitOps root application..."

kubectl apply \
  --namespace "${ARGOCD_NAMESPACE}" \
  -f "${PROJECT_ROOT}/argocd/app-of-apps/cloud-native-platform.yaml"

echo
echo "App-of-apps applied. ArgoCD will create the environment Applications from Git."
echo
echo "Inspect with:"
echo "kubectl get applications -n ${ARGOCD_NAMESPACE}"
