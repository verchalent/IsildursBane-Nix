# Host Setup

Per-machine first-time setup for each host in IsildursBane-Nix.

---

## toyotama — M4 MacBook Air

### Prerequisites

**Age key** already exists at `~/.config/sops/age/keys.txt` (from Toyotama-Nix). Verify:
```bash
cat ~/.config/sops/age/keys.txt
```

**SSH signing key** is in 1Password (same key used in Toyotama-Nix).

### First Apply

```bash
cd ~/src/IsildursBane-Nix

# Encrypt secrets (opens editor; save to encrypt in-place):
sops secrets/toyotama.yaml

# Apply:
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#toyotama
```

### Subsequent Rebuilds

```bash
nixswitch    # darwin-rebuild switch --flake ...#toyotama
nixup        # brew update + flake update + rebuild
```

---

## ungyo: Mac mini (new or replacement machine)

`ungyo` is a host entry like any other. For a replacement Mac (new hardware, same role), follow
the runbook below under the existing name, or add a new host (see "Adding a New macOS Host" in
the README) and retire this one. The age key is **per machine**, so a new Mac needs a new key
and a re-created secrets file; step 6 covers it.

---

## New Mac: blank to conformed

Order matters: several steps cannot work until an earlier one is done. Times are **estimates**
for a fast connection, to be replaced with measured values on the next real run (see the table
at the end).

Hands-on = you must be at the machine. Everything else is waiting.

| # | Step | Hands-on? | Est. time |
|---|------|-----------|-----------|
| 1 | macOS setup, Apple ID, **sign into the App Store** | yes | 10 min |
| 2 | Command Line Tools | start, then wait | 3–10 min |
| 3 | Homebrew | wait | 1–3 min |
| 4 | Nix (Determinate installer) | wait | 1–2 min |
| 5 | 1Password: install, sign in, enable SSH agent; clone repo | yes | 5 min |
| 6 | age key, `.sops.yaml`, secrets file | yes | 3 min |
| 7 | Hostname + first `darwin-rebuild switch` | start, then wait | 20–60 min |
| 8 | Manual post-steps (logins, permissions) | yes | 15 min |

### 1. macOS setup and the App Store

Finish Setup Assistant and sign in to the Apple ID. **Open the App Store and sign in**: the
config installs Mac App Store apps (`homebrew.masApps`), and `mas` cannot sign in for you.
Without this the first switch fails partway through the Homebrew step.

### 2. Command Line Tools (provides `git`)

```bash
xcode-select --install     # accept the dialog, wait for it to finish
```

### 3. Homebrew

nix-darwin manages Homebrew packages but does not install Homebrew itself.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 4. Nix

Hosts that set `nix.enable = false` (ungyo) use the Determinate installer. It enables flakes
by default. (toyotama uses the standard installer: `sh <(curl -L https://nixos.org/nix/install)`.)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Open a new terminal afterwards so `nix` is on `PATH`.

### 5. 1Password and the repo

The repo is private, so cloning needs an SSH key, and the keys live in 1Password.

```bash
brew install --cask 1password
```

Open 1Password, sign in, then Settings → Developer → enable **Use the SSH agent**, and add the
suggested `IdentityAgent` lines to `~/.ssh/config`. Then:

```bash
mkdir -p ~/src && git clone git@github.com:verchalent/IsildursBane-Nix.git ~/src/IsildursBane-Nix
```

(The 1Password cask is declared in the config too, so the later switch simply adopts it.)

### 6. age key and secrets

The first switch decrypts `secrets/<host>.yaml` during activation, so the key must exist
**before** it. `age` is only installed by the switch itself, so borrow it from nixpkgs:

```bash
mkdir -p ~/.config/sops/age && chmod 700 ~/.config/sops/age
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
grep "^# public" ~/.config/sops/age/keys.txt        # the public key for .sops.yaml
```

Save `keys.txt` in 1Password as well. Losing it means re-doing this step.

Then, in the repo:

1. Put the new public key in `.sops.yaml` (replace the old `&ungyo` value, or add a new
   anchor and `creation_rules` entry for a new host name).
2. The old `secrets/ungyo.yaml` is encrypted to the old machine's key and cannot be opened
   here. Its only content is a **public** SSH key, so re-create it rather than re-key:
   in 1Password, create (or open) the signing key for this machine and copy its public key, then
   ```bash
   git rm secrets/ungyo.yaml        # only when reusing the name
   nix shell nixpkgs#sops -c sops secrets/ungyo.yaml
   ```
   and enter `git_signing_key: "ssh-ed25519 AAAA..."`; saving encrypts it.
3. Commit and push `.sops.yaml` and the secrets file.

### 7. Hostname and first switch

The flake key and the machine hostname must match.

```bash
sudo scutil --set HostName ungyo
sudo scutil --set LocalHostName ungyo
sudo scutil --set ComputerName ungyo
```

The first run uses `nix run` because `darwin-rebuild` is not installed yet. Recent nix-darwin
requires root for this (check the nix-darwin README if the command changes again):

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/src/IsildursBane-Nix#ungyo
```

If it stops with `Unexpected files in /etc`, move each listed file aside and re-run, e.g.
`sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin`.

This is the long step: Nix store downloads, then every Homebrew cask (all are `greedy`) and
Mac App Store app. After it succeeds, open a new terminal; `nixswitch` and `nixup` now exist.

### 8. Manual steps no config can do

- 1Password: sign in to the CLI integration (Settings → Developer → "Integrate with 1Password CLI").
- Git signing: confirm the 1Password key is enabled in the SSH agent (the commit-signing path
  is set in `git.nix`).
- LuLu, Tailscale (if installed on the host): approve the system/network extensions in System
  Settings → Privacy & Security, and sign in.
- Bartender, Raycast, AltTab and similar: grant Accessibility / Screen Recording when prompted.
- Brave and other browsers: sign in / sync.
- FileVault and Touch ID: enable if not already.

### Measured timings (fill in on the next run)

| Step | Estimate | Measured | Notes |
|------|----------|----------|-------|
| 2 CLT | 3–10 min | | |
| 3 Homebrew | 1–3 min | | |
| 4 Nix | 1–2 min | | |
| 5 1Password + clone | 5 min | | |
| 6 age + secrets | 3 min | | |
| 7 first switch | 20–60 min | | |
| 8 manual steps | 15 min | | |

### Making it faster

- Do step 1 (App Store login) before anything else, so nothing stalls halfway.
- Steps 2–4 need no attention once started: kick them off in separate tabs one after another.
- The first switch is dominated by downloads (casks and `masApps`). To shorten it, trim what the
  host installs by default; the Brew audit suggestions are in the vault.
