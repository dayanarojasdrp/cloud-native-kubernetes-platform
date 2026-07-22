#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="cloud-native-platform"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/kind/cluster-config.yaml"
RESET_CLUSTER="${RESET_CLUSTER:-false}"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

echo "Checking Docker..."

if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker is not running."
  echo "Start Docker Desktop and run this script again."
  exit 1
fi

echo "Checking required commands..."

for command in kind kubectl docker; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Error: ${command} is not installed."
    exit 1
  fi
done

if [[ "${RESET_CLUSTER}" == "true" ]] && kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Deleting existing Kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "${CLUSTER_NAME}"
fi

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists."
else
  echo "Creating Kind cluster '${CLUSTER_NAME}'..."

  kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config "${CONFIG_FILE}" \
    --wait 120s
fi

echo "Selecting kubectl context..."

kubectl config use-context "kind-${CLUSTER_NAME}"

echo "Waiting for Kubernetes nodes..."

kubectl wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=120s

echo
echo "Cluster nodes:"
kubectl get nodes -o wide

echo
echo "Kind cluster is ready."
