#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/load-env.sh"

if [ -z "${HCLOUD_TOKEN:-}" ]; then
  echo "Put HCLOUD_TOKEN in .env (see .env.example) or export it." >&2
  exit 1
fi

if [ ! -f "$HOME/.ssh/k3s-lab" ]; then
  ssh-keygen -q -t ed25519 -N '' -f "$HOME/.ssh/k3s-lab" -C 'k3s-hetzner-lab'
fi
chmod 600 "$HOME/.ssh/k3s-lab"
chmod 644 "$HOME/.ssh/k3s-lab.pub"

terraform init
terraform apply
./get-kubeconfig.sh
