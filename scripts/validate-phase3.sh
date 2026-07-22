#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="users-api"
TEST_NAMESPACE="network-policy-test"
INGRESS_HOSTNAME="${INGRESS_HOSTNAME:-users-api.local}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="${PROJECT_ROOT}/.bin:${PATH}"

cleanup() {
  kubectl delete namespace "${TEST_NAMESPACE}" --ignore-not-found >/dev/null 2>&1 || true
  rm -f /tmp/direct-db-test.log
}

trap cleanup EXIT

echo "Validating persistent storage..."
kubectl get pvc postgres-data --namespace "${NAMESPACE}"
kubectl get pv

echo
echo "Validating NetworkPolicy resources..."
kubectl get networkpolicy --namespace "${NAMESPACE}"

echo
echo "Validating application readiness through HTTPS Ingress..."
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
echo "Creating a persistence test user..."
TEST_EMAIL="phase3-persistence-$(date +%s)@example.com"

curl \
  --fail \
  --silent \
  --show-error \
  --insecure \
  --noproxy "*" \
  --resolve "${INGRESS_HOSTNAME}:443:127.0.0.1" \
  -X POST \
  "https://${INGRESS_HOSTNAME}/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Phase Three\",\"email\":\"${TEST_EMAIL}\",\"age\":30}" \
  >/dev/null

echo "Restarting PostgreSQL pod to verify PVC-backed persistence..."
POSTGRES_POD="$(kubectl get pods --namespace "${NAMESPACE}" -l app.kubernetes.io/name=postgres -o jsonpath='{.items[0].metadata.name}')"
kubectl delete pod "${POSTGRES_POD}" --namespace "${NAMESPACE}"
kubectl rollout status deployment/postgres --namespace "${NAMESPACE}" --timeout=180s
kubectl rollout status deployment/users-api --namespace "${NAMESPACE}" --timeout=180s

echo
echo "Checking that the user still exists after PostgreSQL restart..."

curl \
  --fail \
  --silent \
  --show-error \
  --insecure \
  --noproxy "*" \
  --resolve "${INGRESS_HOSTNAME}:443:127.0.0.1" \
  "https://${INGRESS_HOSTNAME}/users" \
  | grep "${TEST_EMAIL}" >/dev/null

echo "Persistence test passed for ${TEST_EMAIL}."

echo
echo "Checking NetworkPolicy enforcement capability..."

if kubectl get pods --namespace kube-system -l k8s-app=calico-node 2>/dev/null | grep -q calico-node; then
  CNI_SUPPORTS_NETWORK_POLICY="true"
elif kubectl get pods --namespace kube-system -l k8s-app=cilium 2>/dev/null | grep -q cilium; then
  CNI_SUPPORTS_NETWORK_POLICY="true"
else
  CNI_SUPPORTS_NETWORK_POLICY="false"
fi

kubectl create namespace "${TEST_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

if [[ "${CNI_SUPPORTS_NETWORK_POLICY}" == "true" ]]; then
  echo "NetworkPolicy-aware CNI detected. Verifying direct DB access is blocked..."

  if kubectl run direct-db-test \
    --namespace "${TEST_NAMESPACE}" \
    --image=curlimages/curl:latest \
    --restart=Never \
    --rm \
    --attach \
    --command -- sh -c "curl --connect-timeout 5 telnet://postgres.${NAMESPACE}.svc.cluster.local:5432" >/tmp/direct-db-test.log 2>&1; then
    echo "Error: direct DB access unexpectedly succeeded."
    cat /tmp/direct-db-test.log
    exit 1
  fi

  echo "Direct DB access from another namespace was blocked."
else
  echo "Current local CNI does not enforce NetworkPolicies."
  echo "NetworkPolicy objects are applied and documented; use Calico or Cilium to test packet-level blocking locally."
fi

echo
echo "Phase 3 validation completed successfully."
