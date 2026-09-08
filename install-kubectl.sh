#!/usr/bin/env bash
set -euo pipefail

if command -v kubectl >/dev/null 2>&1; then
  echo "kubectl already installed: $(command -v kubectl)"
  exit 0
fi

arch="$(uname -m)"
case "$arch" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
esac

version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl"
chmod 0755 /tmp/kubectl
if [ "$(id -u)" -eq 0 ]; then
  mv /tmp/kubectl /usr/local/bin/kubectl
else
  mkdir -p "$HOME/.local/bin"
  mv /tmp/kubectl "$HOME/.local/bin/kubectl"
  echo "Add $HOME/.local/bin to PATH if kubectl is not found."
fi
