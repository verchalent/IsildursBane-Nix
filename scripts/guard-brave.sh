#!/usr/bin/env bash
# Run before anything that may replace the Brave app (brew upgrade, darwin-rebuild).
# Replacing the app bundle while it runs resets its macOS Local Network permission and
# leaves the running copy half-updated, so ask to quit it first.
#   SKIP_BRAVE_GUARD=1 bypasses the check.
set -euo pipefail

[ "$(uname -s)" = Darwin ] || exit 0
[ -z "${SKIP_BRAVE_GUARD:-}" ] || exit 0
/usr/bin/pgrep -x "Brave Browser" >/dev/null || exit 0

echo "Brave is running. Updating can replace the app, which resets its Local Network permission."
if [ -t 0 ]; then
  read -r -p "Quit Brave now? [y/N] " ans
  case "$ans" in
    y|Y|yes)
      /usr/bin/osascript -e 'tell application "Brave Browser" to quit' >/dev/null 2>&1 || true
      for _ in $(seq 1 20); do
        /usr/bin/pgrep -x "Brave Browser" >/dev/null || { echo "Brave closed."; exit 0; }
        sleep 0.5
      done
      echo "Brave did not quit in time; close it yourself and re-run." >&2
      exit 1 ;;
  esac
fi
echo "Aborting: close Brave and re-run (or SKIP_BRAVE_GUARD=1 to continue anyway)." >&2
exit 1
