#!/usr/bin/env bash

set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_VERSION="${ARGOCD_VERSION:-stable}"
MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
MANIFEST_FILE="$(mktemp)"

cleanup() {
  rm -f "${MANIFEST_FILE}"
}

trap cleanup EXIT

echo "Installing ArgoCD into namespace '${ARGOCD_NAMESPACE}'..."

kubectl create namespace "${ARGOCD_NAMESPACE}" \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -

curl --fail --silent --show-error --location "${MANIFEST_URL}" \
  > "${MANIFEST_FILE}"

kubectl apply \
  --namespace "${ARGOCD_NAMESPACE}" \
  -f "${MANIFEST_FILE}"

echo "Waiting for ArgoCD Deployments..."

kubectl wait \
  --namespace "${ARGOCD_NAMESPACE}" \
  --for=condition=Available \
  deployment/argocd-applicationset-controller \
  deployment/argocd-dex-server \
  deployment/argocd-notifications-controller \
  deployment/argocd-redis \
  deployment/argocd-repo-server \
  deployment/argocd-server \
  --timeout=300s

kubectl wait \
  --namespace "${ARGOCD_NAMESPACE}" \
  --for=condition=Ready \
  pod \
  --selector=app.kubernetes.io/name=argocd-application-controller \
  --timeout=300s

echo
echo "ArgoCD is ready."
echo
echo "Access the UI locally with:"
echo "kubectl port-forward service/argocd-server 8081:443 -n ${ARGOCD_NAMESPACE}"
