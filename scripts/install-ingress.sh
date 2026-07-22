#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${PROJECT_ROOT}/.bin:${PATH}"

INGRESS_NGINX_VERSION="${INGRESS_NGINX_VERSION:-controller-v1.15.1}"
MANIFEST_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml"
MANIFEST_FILE="$(mktemp)"

cleanup() {
  rm -f "${MANIFEST_FILE}"
}

trap cleanup EXIT

echo "Installing ingress-nginx ${INGRESS_NGINX_VERSION} for Kind..."

curl --fail --silent --show-error --location "${MANIFEST_URL}" \
  | sed -E 's/@sha256:[a-f0-9]+//g' \
  > "${MANIFEST_FILE}"

kubectl delete job ingress-nginx-admission-create \
  --namespace ingress-nginx \
  --ignore-not-found

kubectl delete job ingress-nginx-admission-patch \
  --namespace ingress-nginx \
  --ignore-not-found

kubectl apply -f "${MANIFEST_FILE}"

echo "Waiting for ingress-nginx controller..."

kubectl wait \
  --namespace ingress-nginx \
  --for=condition=Ready \
  pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo
echo "Ingress controller is ready."
