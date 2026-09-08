#!/usr/bin/env bash
set -euo pipefail

server_ip="$(terraform output -raw server_public_ip)"
key="$HOME/.ssh/k3s-lab"
kubeconfig="$HOME/.kube/k3s-hetzner.yaml"
mkdir -p "$HOME/.kube"
# Recycled Hetzner IPv4s keep the same address; drop the stale host key.
ssh-keygen -R "$server_ip" >/dev/null 2>&1 || true

for attempt in $(seq 1 60); do
  if ssh -i "$key" -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
      "root@${server_ip}" 'cat /etc/rancher/k3s/k3s.yaml' 2>/dev/null \
      | sed "s/127.0.0.1/${server_ip}/" >"${kubeconfig}.tmp"; then
    if [ -s "${kubeconfig}.tmp" ]; then
      mv "${kubeconfig}.tmp" "$kubeconfig"
      chmod 600 "$kubeconfig"
      echo "Kubeconfig: $kubeconfig"
      echo "Use: export KUBECONFIG=$kubeconfig"
      exit 0
    fi
  fi
  rm -f "${kubeconfig}.tmp"
  sleep 5
done

echo "K3s did not become ready within 5 minutes." >&2
exit 1
