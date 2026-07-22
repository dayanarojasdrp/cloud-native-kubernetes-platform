# Network Policies

Phase 3 defines namespace-level ingress restrictions for the Users API platform.

## Policies

- `default-deny-ingress`: denies inbound traffic to all Pods in the `users-api` namespace unless another policy allows it.
- `allow-ingress-to-api-from-ingress-controller`: allows only the `ingress-nginx` controller to reach the API Pods on port `8080`.
- `allow-api-to-db`: allows only Users API Pods to reach PostgreSQL on port `5432`.
- `deny-direct-db-access-from-other-namespaces`: documents and reinforces the database deny-by-default boundary.

## Local CNI Note

Kind's default `kindnet` CNI accepts NetworkPolicy objects but does not enforce them. These manifests are valid Kubernetes security policy definitions. For local enforcement tests, recreate the cluster with a NetworkPolicy-aware CNI such as Calico or Cilium.
