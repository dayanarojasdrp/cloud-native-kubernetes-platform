# Observability

This repository focuses on Kubernetes platform delivery and operational evidence. Full Prometheus/Grafana installation is intentionally left as an extension point so the core platform remains lightweight and reproducible on a local Kind cluster.

## Current Signals

The platform currently demonstrates operational visibility through Kubernetes-native signals:

- Pod readiness and status
- Deployment rollout history and rollout status
- Ingress availability
- HPA object status
- PVC binding status
- NetworkPolicy inventory
- Helm release state
- ArgoCD Application resources

These are captured by:

```bash
./scripts/capture-evidence.sh
```

## Recommended Production Extension

For a production-style observability layer, add or connect:

- kube-prometheus-stack
- Grafana dashboards for API latency, error rate, CPU, memory, and Pod restarts
- alert rules for unavailable Deployments, failed rollouts, and PVC pressure
- ingress-nginx metrics
- PostgreSQL exporter metrics

## Interview Framing

The key point is that this platform already exposes the Kubernetes objects that Prometheus would scrape or alert on. The next step is wiring those signals into a metrics backend and dashboards.
