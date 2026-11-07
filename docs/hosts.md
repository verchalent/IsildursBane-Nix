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

Two parts: a short list of things only a human can do **before** the script (about 20 minutes),
then one script that does everything else and refuses to start the long install unless every
prerequisite it can check is in place.

### Part 1: do these by hand first (the script cannot)

| # | Manual step | Why it cannot be automated |
|---|-------------|----------------------------|
| 1 | Finish macOS setup and sign in to the Apple ID | Setup Assistant |
| 2 | Open the **App Store** and sign in | `mas` cannot sign in; the install of Mac App Store apps fails otherwise |
| 3 | `xcode-select --install`, accept, wait | Gives you `git`; a GUI dialog |
| 4 | Install **1Password** (`brew`-free: download the app from 1password.com), sign in, enable *Settings → Developer → Use the SSH agent*, add the suggested lines to `~/.ssh/config` | The repo is private; your keys live there |
| 5 | In 1Password, create this machine's **SSH signing key** (ed25519) and keep its *public* key handy | The script asks you to paste it |
| 6 | `mkdir -p ~/src && git clone git@github.com:verchalent/IsildursBane-Nix.git ~/src/IsildursBane-Nix` | Needs steps 3 and 4 |

You do **not** need to create the age key yourself: the script generates it. You **do** need
to save it in 1Password when the script says so (losing it just means repeating the key step).

### Part 2: run the script

```bash
cd ~/src/IsildursBane-Nix
scripts/bootstrap-darwin.sh --check ungyo     # read-only: lists every problem at once
scripts/bootstrap-darwin.sh ungyo             # the real run
```

`--check` changes nothing. The real run does the same checks first and **stops with the full list
of problems before touching anything**. It then runs these phases, each safe to repeat; after
fixing whatever stopped it, simply run it again:

1. Homebrew (not installed by nix-darwin itself).
2. Nix (Determinate installer, flakes on by default).
3. This machine's age key (`~/.config/sops/age/keys.txt`), generated if missing.
4. **Secrets gate:** proves this machine can decrypt `secrets/<host>.yaml` *before* the long
   step. A replacement Mac has a new key, so the old file cannot be opened; if the file only
   holds the git signing public key (as `ungyo` does) the script updates `.sops.yaml`, asks you
   to paste the public key from step 5, re-encrypts, and commits locally. If the file holds
   other secrets it stops and tells you exactly how to re-key it from a machine that can still
   decrypt it. Push the resulting commit when convenient.
5. Hostname (flake name and machine name must match).
6. Moves the stock `/etc/bashrc` and `/etc/zshrc` aside, which nix-darwin otherwise refuses to overwrite.
7. The first `darwin-rebuild switch`: the long step (Nix store, then every cask and App Store app).

At the end it prints how long each phase took; paste those into the table below.

If something still fails inside the switch (a cask download, a network blip), re-run the script:
it skips what is done and the switch is itself idempotent.

### After the switch (manual)

- 1Password: *Settings → Developer → Integrate with 1Password CLI*.
- Git signing: confirm this machine's signing key is enabled in the 1Password SSH agent.
- LuLu, Tailscale (where installed): approve system/network extensions in System Settings →
  Privacy & Security and sign in.
- Bartender, Raycast, AltTab and similar: grant Accessibility / Screen Recording when prompted.
- Browsers: sign in / sync. FileVault and Touch ID: enable if not already.

### Doing it by hand (what the script runs)

Same order, for reference or if the script is unavailable: Homebrew
(`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`),
Nix (`curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`),
age key (`nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt`, then `chmod 600`),
secrets (`.sops.yaml` + `sops secrets/<host>.yaml`), hostname (`scutil --set HostName|LocalHostName|ComputerName`),
then `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/src/IsildursBane-Nix#<host>`.
If it stops with `Unexpected files in /etc`, move the listed files aside
(`sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin`).

### Measured timings (fill in from the script's summary on the next real run)

| Phase | Estimate | Measured | Notes |
|-------|----------|----------|-------|
| Part 1 (manual) | 20 min | | |
| Homebrew | 1–3 min | | |
| Nix | 1–2 min | | |
| age key + secrets gate | 3 min | | |
| first switch | 20–60 min | | |
| After the switch (manual) | 15 min | | |

### Making it faster

- Do Part 1 completely first; nothing then stalls halfway for a login.
- The first switch is dominated by downloads (casks and `masApps`). Trimming what the host
  installs by default shortens it most; see the Brew audit suggestions in the vault.
