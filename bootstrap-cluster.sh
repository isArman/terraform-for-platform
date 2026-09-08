#!/usr/bin/env bash
set -euo pipefail

# Wait for K3s, then install the Chapter 2 Conference app.
# K3s already ships Traefik; do not install ingress-nginx (it fights Traefik on :80/:443).

root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"

expected_nodes="${EXPECTED_NODES:-3}"
chart_version="${CONFERENCE_CHART_VERSION:-v1.0.0}"
values_file="${root}/conference-values.yaml"

./get-kubeconfig.sh
./install-kubectl.sh
./install-helm.sh

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/k3s-hetzner.yaml}"

echo "Waiting for all $expected_nodes K3s nodes to register..."
for attempt in $(seq 1 60); do
  node_count="$(kubectl get nodes --no-headers 2>/dev/null | wc -l || true)"
  if [ "$node_count" -eq "$expected_nodes" ]; then
    break
  fi
  if [ "$attempt" -eq 60 ]; then
    echo "Expected $expected_nodes nodes, found $node_count after 5 minutes" >&2
    kubectl get nodes -o wide || true
    exit 1
  fi
  sleep 5
done
kubectl wait --for=condition=Ready nodes --all --timeout=5m
kubectl get nodes -o wide

helm upgrade --install conference oci://docker.io/salaboy/conference-app \
  --version "$chart_version" \
  -f "$values_file" \
  --timeout 10m

# Chart v1.0.0 hardcodes ingressClassName: nginx; this cluster uses Traefik.
for attempt in $(seq 1 30); do
  if kubectl get ingress conference-frontend-ingress -n default >/dev/null 2>&1; then
    kubectl patch ingress conference-frontend-ingress -n default --type merge \
      -p '{"spec":{"ingressClassName":"traefik"}}'
    break
  fi
  sleep 2
done

# StatefulSets may keep old pods after an image override; bounce them if they are still pulling bitnami/*.
for sts_pod in conference-postgresql-0 conference-redis-master-0 conference-kafka-0; do
  image="$(kubectl get pod "$sts_pod" -n default -o jsonpath='{.spec.containers[0].image}' 2>/dev/null || true)"
  if [[ "$image" == docker.io/bitnami/* ]] || [[ "$image" == bitnami/* ]]; then
    kubectl delete pod "$sts_pod" -n default --wait=false || true
  fi
done

echo "Waiting for Conference pods..."
if ! kubectl wait --for=condition=Ready pods --all -n default --timeout=12m; then
  echo "Some pods are not Ready yet:" >&2
  kubectl get pods -n default -o wide || true
  exit 1
fi

kubectl get pods,ingress,svc -n default
server_ip="$(terraform output -raw server_public_ip)"
echo "Conference UI: http://${server_ip}/"
echo "KUBECONFIG=$KUBECONFIG"
