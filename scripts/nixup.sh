#!/usr/bin/env bash
# Update flake inputs and rebuild the current machine's configuration.
# The nixup zsh alias calls this (after brewup). On success, commits and
# pushes flake.lock to main so the other Mac picks it up with a plain pull.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTNAME="$(hostname -s)"

cd "${REPO_DIR}"

# Don't replace Brave while it runs (resets its Local Network permission).
"${REPO_DIR}/scripts/guard-brave.sh"
BRAVE_APP="/Applications/Brave Browser.app"
brave_stamp() { /usr/bin/stat -f %m "${BRAVE_APP}" 2>/dev/null || echo none; }
BRAVE_BEFORE="$(brave_stamp)"

echo "==> Syncing repo..."
git pull --rebase --autostash

echo "==> Updating flake inputs..."
nix flake update

echo "==> Rebuilding ${HOSTNAME}..."
if ! sudo darwin-rebuild switch --flake "${REPO_DIR}#${HOSTNAME}"; then
  echo "==> Rebuild failed; clearing Nix fetch caches and retrying once..."
  rm -rf ~/.cache/nix/tarball-cache
  rm -f ~/.cache/nix/fetcher-cache-v4.sqlite*
  sudo darwin-rebuild switch --flake "${REPO_DIR}#${HOSTNAME}"
fi

# Only reached if the rebuild succeeded, so a broken lock is never pushed.
if git diff --quiet -- flake.lock; then
  echo "==> flake.lock unchanged; nothing to push."
else
  echo "==> Committing flake.lock..."
  git add flake.lock
  git commit -m "flake.lock: update $(date +%F) (${HOSTNAME})" -- flake.lock
  git push || echo "==> WARNING: push failed; flake.lock is committed locally. Push it manually." >&2
fi

if [ "$(brave_stamp)" != "${BRAVE_BEFORE}" ]; then
  echo "==> Brave was replaced during this run: open it and allow the Local Network prompt if it appears."
fi
