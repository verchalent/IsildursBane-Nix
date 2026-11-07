#!/usr/bin/env bash
# Take a fresh Mac from "repo cloned" to "fully conformed" with the config for <hostname>.
#
#   scripts/bootstrap-darwin.sh [--check] [--yes] <hostname>
#
#   --check   run the read-only preflight and stop (changes nothing)
#   --yes     skip the interactive confirmations (App Store, overwrite prompts)
#
# Design: everything that can be verified WITHOUT changing the machine is checked first
# and reported together, so a missing prerequisite stops the run before anything happens.
# The second gate (secrets) runs after the cheap installs but BEFORE the long first switch.
# Every phase is idempotent: after fixing a problem, just run the script again.
# Must run on macOS (system bash 3.2 is fine: no bashisms beyond that).
set -euo pipefail

CHECK_ONLY=0
ASSUME_YES=0
HOST=""
for arg in "$@"; do
  case "$arg" in
    --check)   CHECK_ONLY=1 ;;
    --yes)     ASSUME_YES=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    -*)        echo "unknown option: $arg" >&2; exit 2 ;;
    *)         HOST="$arg" ;;
  esac
done
[ -n "$HOST" ] || { echo "usage: $0 [--check] [--yes] <hostname>" >&2; exit 2; }

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGE_KEY="$HOME/.config/sops/age/keys.txt"
SECRETS="secrets/$HOST.yaml"
TIMINGS=""

say()  { printf '\n==> %s\n' "$*"; }
ok()   { printf '    ok   %s\n' "$*"; }
warn() { printf '    WARN %s\n' "$*"; }
PROBLEMS=0
bad()  { printf '    FAIL %s\n' "$*"; PROBLEMS=$((PROBLEMS + 1)); }
confirm() { # confirm "question" -> 0 if yes
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ -t 0 ] || return 1
  read -r -p "$1 [y/N] " ans
  case "$ans" in y|Y|yes) return 0 ;; *) return 1 ;; esac
}
timed() { # timed "label" cmd...
  local label="$1" start=$SECONDS; shift
  "$@"
  TIMINGS="$TIMINGS$(printf '%-34s %4ds\n' "$label" $((SECONDS - start)))"$'\n'
}

# ---------------------------------------------------------------- preflight (read-only)
preflight() {
  say "Preflight for '$HOST' (nothing is changed here)"

  [ "$(uname -s)" = Darwin ] && ok "macOS" || bad "not macOS"
  [ "$(uname -m)" = arm64 ] && ok "Apple silicon" || bad "not Apple silicon (flake targets aarch64-darwin)"
  [ "$(id -u)" -ne 0 ] && ok "running as a normal user" || bad "run as your normal user, not root"
  xcode-select -p >/dev/null 2>&1 && ok "Command Line Tools installed" \
    || bad "Command Line Tools missing: run 'xcode-select --install', wait, then re-run"

  [ -f "$REPO/hosts/$HOST/default.nix" ] && ok "hosts/$HOST exists" || bad "no hosts/$HOST/default.nix in this repo"
  grep -Eq "^[[:space:]]*$HOST[[:space:]]*=[[:space:]]*mkDarwinSystem" "$REPO/flake.nix" \
    && ok "'$HOST' is a darwinConfiguration in flake.nix" || bad "'$HOST' is not registered in flake.nix"
  [ -f "$REPO/$SECRETS" ] && ok "$SECRETS exists" || warn "$SECRETS missing: gate 2 will offer to create it"
  grep -q "&$HOST " "$REPO/.sops.yaml" && ok ".sops.yaml has an entry for '$HOST'" \
    || bad ".sops.yaml has no '&$HOST' key anchor (see README: Adding a New macOS Host)"

  free_gb="$(df -g / | awk 'NR==2 {print $4}')"
  [ "${free_gb:-0}" -ge 30 ] && ok "${free_gb} GiB free" || bad "only ${free_gb:-?} GiB free; need about 30"

  curl -fsS -m 10 -o /dev/null https://github.com && ok "github.com reachable" || bad "cannot reach github.com"
  curl -fsS -m 10 -o /dev/null https://cache.nixos.org/nix-cache-info && ok "cache.nixos.org reachable" \
    || bad "cannot reach cache.nixos.org"
  git -C "$REPO" ls-remote --exit-code origin HEAD >/dev/null 2>&1 \
    && ok "git can reach origin (SSH agent works)" \
    || bad "git cannot reach origin: sign in to 1Password and enable its SSH agent"

  [ -d /Applications/1Password.app ] && ok "1Password installed" \
    || warn "1Password not in /Applications yet (the config installs it, but you need it for git/SSH)"

  if [ "$(scutil --get HostName 2>/dev/null || true)" != "$HOST" ]; then
    warn "HostName is '$(scutil --get HostName 2>/dev/null || echo unset)'; the script will set it to '$HOST'"
  else
    ok "HostName already '$HOST'"
  fi

  if [ "$CHECK_ONLY" -eq 0 ]; then
    if confirm "Are you signed in to the Mac App Store? (cannot be checked automatically; the install of masApps fails otherwise)"; then
      ok "App Store sign-in confirmed by you"
    else
      bad "sign in to the App Store, then re-run (or pass --yes to skip this question)"
    fi
  else
    warn "App Store sign-in cannot be checked automatically: make sure you are signed in"
  fi

  if [ "$PROBLEMS" -gt 0 ]; then
    printf '\n%d problem(s) found. Nothing has been changed. Fix them and re-run.\n' "$PROBLEMS" >&2
    exit 1
  fi
  say "Preflight passed"
  if [ "$CHECK_ONLY" -eq 1 ]; then echo "(--check: stopping here)"; exit 0; fi
}

# ---------------------------------------------------------------- phases
phase_sudo() {
  say "Administrator access (asked once, kept alive for the run)"
  sudo -v
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

phase_homebrew() {
  if [ -x /opt/homebrew/bin/brew ]; then ok "Homebrew already installed"; return; fi
  say "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

load_nix() {
  # shellcheck disable=SC1091
  [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] \
    && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  return 0
}

phase_nix() {
  load_nix
  if command -v nix >/dev/null; then ok "Nix already installed"; return; fi
  say "Installing Nix (Determinate installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  load_nix
  command -v nix >/dev/null || { echo "nix not on PATH after install; open a new terminal and re-run" >&2; exit 1; }
}

phase_age_key() {
  if [ -f "$AGE_KEY" ]; then ok "age key exists ($AGE_KEY)"; return; fi
  say "Generating this machine's age key"
  mkdir -p "$(dirname "$AGE_KEY")"; chmod 700 "$(dirname "$AGE_KEY")"
  nix shell nixpkgs#age -c age-keygen -o "$AGE_KEY"
  chmod 600 "$AGE_KEY"
  echo "    IMPORTANT: save $AGE_KEY in 1Password now. It cannot be recovered."
}

age_pub() { grep '^# public key:' "$AGE_KEY" | awk '{print $4}'; }

# Gate 2: the first switch decrypts secrets/<host>.yaml during activation. Verify that now,
# so a key mismatch is caught in seconds instead of after a 30-minute install.
gate_secrets() {
  say "Gate: can this machine decrypt $SECRETS?"
  export SOPS_AGE_KEY_FILE="$AGE_KEY"
  pub="$(age_pub)"
  cd "$REPO"

  if [ -f "$SECRETS" ] && nix shell nixpkgs#sops -c sops --decrypt "$SECRETS" >/dev/null 2>&1; then
    ok "decrypts with this machine's key"
    return
  fi

  echo "    $SECRETS is missing or encrypted to a different (old) machine's key."
  # Key names are plaintext in a sops file, so we can tell what it holds without decrypting.
  names=""
  [ -f "$SECRETS" ] && names="$(grep -E '^[A-Za-z_]+:' "$SECRETS" | grep -v '^sops:' | tr -d ':' | tr '\n' ' ')"
  if [ -n "$names" ] && [ "$names" != "git_signing_key " ]; then
    cat >&2 <<MSG
    This file holds more than the signing key ($names).
    It must be re-keyed from a machine that CAN decrypt it:
      1. add this machine's public key to .sops.yaml:  $pub
      2. on the other machine: sops updatekeys $SECRETS, commit, push
    then pull here and re-run this script. Nothing has been changed except installs.
MSG
    exit 1
  fi

  echo "    It only needs the git signing PUBLIC key, which is safe to re-create."
  confirm "Create/replace $SECRETS with this machine's key now?" || {
    echo "    Skipped. Re-run when ready." >&2; exit 1; }

  echo "    In 1Password, create or open this machine's SSH signing key and copy its PUBLIC key."
  if [ -t 0 ]; then
    read -r -p "    Paste the public key (ssh-ed25519 AAAA...): " sshpub
  else
    echo "    No terminal to ask on; run interactively." >&2; exit 1
  fi
  case "$sshpub" in ssh-ed25519\ *|ssh-rsa\ *|ecdsa-*) ;; *) echo "    That is not an SSH public key." >&2; exit 1 ;; esac

  # Point .sops.yaml at this machine's key, then encrypt the new file.
  sed -i '' -E "s|(&$HOST )age1[a-z0-9]+|\\1$pub|" .sops.yaml
  grep -q "$pub" .sops.yaml || { echo "    could not update .sops.yaml" >&2; exit 1; }
  printf 'git_signing_key: "%s"\n' "$sshpub" \
    | nix shell nixpkgs#sops -c sops --encrypt --input-type yaml --output-type yaml \
        --filename-override "$SECRETS" /dev/stdin > "$SECRETS.new"
  mv "$SECRETS.new" "$SECRETS"
  nix shell nixpkgs#sops -c sops --decrypt "$SECRETS" >/dev/null \
    || { echo "    re-encrypted file does not decrypt; aborting" >&2; exit 1; }
  git add .sops.yaml "$SECRETS"
  git commit -q -m "$HOST: new age key and signing key secret"
  ok "secrets re-created and committed locally"
  echo "    Push when convenient (it is needed by other machines only: git push)."
}

phase_hostname() {
  for k in HostName LocalHostName ComputerName; do
    [ "$(scutil --get "$k" 2>/dev/null || true)" = "$HOST" ] || sudo scutil --set "$k" "$HOST"
  done
  ok "hostname is $HOST"
}

phase_etc() {
  # nix-darwin refuses to overwrite stock /etc files; moving them aside is lossless.
  for f in /etc/bashrc /etc/zshrc; do
    if [ -f "$f" ] && [ ! -L "$f" ] && [ ! -e "$f.before-nix-darwin" ]; then
      sudo mv "$f" "$f.before-nix-darwin"
      ok "moved $f aside"
    fi
  done
}

phase_switch() {
  say "First switch for '$HOST' (the long step: Nix store, then casks and App Store apps)"
  if command -v darwin-rebuild >/dev/null; then
    sudo darwin-rebuild switch --flake "$REPO#$HOST"
  else
    sudo -H nix run nix-darwin/master#darwin-rebuild -- switch --flake "$REPO#$HOST"
  fi
}

# ---------------------------------------------------------------- run
preflight
phase_sudo
timed "Homebrew"            phase_homebrew
timed "Nix"                 phase_nix
timed "age key"             phase_age_key
timed "secrets gate"        gate_secrets
timed "hostname"            phase_hostname
timed "/etc cleanup"        phase_etc
timed "first switch"        phase_switch

say "Done. Timings (paste into docs/hosts.md, measured table):"
printf '%s' "$TIMINGS"
cat <<'MSG'

Open a new terminal. Manual steps that remain are listed in docs/hosts.md under
"After the switch" (1Password CLI integration, LuLu/Tailscale approvals, browser sign-ins).
MSG
