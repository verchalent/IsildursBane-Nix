#!/usr/bin/env bash
# Update flake inputs and rebuild the current machine's configuration.
# The nixswitch/nixup zsh aliases call this from the repo root.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTNAME="$(hostname -s)"

echo "==> Updating flake inputs..."
nix flake update

echo "==> Rebuilding ${HOSTNAME}..."
if ! sudo darwin-rebuild switch --flake "${REPO_DIR}#${HOSTNAME}"; then
  echo "==> Rebuild failed; clearing Nix fetch caches and retrying once..."
  rm -rf ~/.cache/nix/tarball-cache
  rm -f ~/.cache/nix/fetcher-cache-v4.sqlite*
  sudo darwin-rebuild switch --flake "${REPO_DIR}#${HOSTNAME}"
fi
