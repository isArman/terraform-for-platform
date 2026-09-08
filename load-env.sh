#!/usr/bin/env bash
# Sourced by up.sh / down.sh. Not meant to be run directly.

env_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env"
if [ -f "$env_file" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
fi
