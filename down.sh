#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")" && pwd)/load-env.sh"

if [ -z "${HCLOUD_TOKEN:-}" ]; then
  echo "Put HCLOUD_TOKEN in .env (see .env.example) or export it." >&2
  exit 1
fi

terraform destroy
rm -f "$HOME/.kube/k3s-hetzner.yaml"
