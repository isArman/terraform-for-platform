#!/usr/bin/env bash
set -euo pipefail

expected_nodes="${EXPECTED_NODES:-3}"
./get-kubeconfig.sh
./install-kubectl.sh
./install-helm.sh

export KUBECONFIG="$HOME/.kube/k3s-hetzner.yaml"
echo "Waiting for all $expected_nodes K3s nodes to register..."
for attempt in $(seq 1 60); do
  node_count="$(kubectl get nodes --no-headers 2>/dev/null | wc -l)"
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

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.kind=DaemonSet \
  --set controller.service.type=ClusterIP

kubectl get nodes -o wide
kubectl -n ingress-nginx get pods
