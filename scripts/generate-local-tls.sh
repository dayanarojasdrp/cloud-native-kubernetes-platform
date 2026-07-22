#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="users-api"
TLS_HOSTNAME="${TLS_HOSTNAME:-users-api.local}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TLS_DIR="${PROJECT_ROOT}/k8s/tls"
CERT_FILE="${TLS_DIR}/${TLS_HOSTNAME}.crt"
KEY_FILE="${TLS_DIR}/${TLS_HOSTNAME}.key"

mkdir -p "${TLS_DIR}"

echo "Generating self-signed certificate for ${TLS_HOSTNAME}..."

openssl req \
  -x509 \
  -nodes \
  -newkey rsa:2048 \
  -keyout "${KEY_FILE}" \
  -out "${CERT_FILE}" \
  -days 365 \
  -subj "/CN=${TLS_HOSTNAME}" \
  -addext "subjectAltName=DNS:${TLS_HOSTNAME}"

echo "Applying TLS Secret users-api-tls in namespace ${NAMESPACE}..."

kubectl create secret tls users-api-tls \
  --namespace "${NAMESPACE}" \
  --cert "${CERT_FILE}" \
  --key "${KEY_FILE}" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo
echo "TLS Secret is ready."
