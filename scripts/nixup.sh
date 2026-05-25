#!/usr/bin/env bash
# Update flake inputs and rebuild the current machine's configuration.
# The nixswitch/nixup zsh aliases call this from the repo root.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTNAME="$(hostname -s)"

echo "==> Updating flake inputs..."
nix flake update

echo "==> Rebuilding ${HOSTNAME}..."
sudo darwin-rebuild switch --flake "${REPO_DIR}#${HOSTNAME}"
