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

## ungyo — M2 Mac Mini

### Prerequisites

#### 1. Generate age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# Print the public key — needed for .sops.yaml:
grep "^# public" ~/.config/sops/age/keys.txt
```

#### 2. Update .sops.yaml

In the repo, replace `<UNGYO_AGE_PUBLIC_KEY>` with the value from step 1:

```yaml
keys:
  - &ungyo age1<the-key-from-step-1>
```

#### 3. Create Ungyo SSH signing key in 1Password

- Open 1Password → New Item → SSH Key
- Generate a new ed25519 key named something like "Ungyo Git Signing Key"
- Enable SSH agent for this key
- Copy the public key (ed25519 format)

#### 4. Encrypt ungyo secrets

```bash
cd ~/src/IsildursBane-Nix

# Edit the template (add the SSH pubkey from step 3), then save — sops encrypts on write:
sops secrets/ungyo.yaml
```

The file should look like this before saving:
```yaml
git_signing_key: "ssh-ed25519 AAAA... <your-ungyo-pubkey>"
```

#### 5. Commit the encrypted secrets + updated .sops.yaml

```bash
git add .sops.yaml secrets/ungyo.yaml
git commit -m "ungyo: add age key and encrypted signing key secret"
git push
```

### First Apply

The machine's current hostname may be `Ungyo` (capital U). Specify the flake attr explicitly:

```bash
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#ungyo
```

This will set `networking.hostName = "ungyo"` (lowercase). After that, `nixswitch` alias works automatically.

### Subsequent Rebuilds

```bash
nixswitch    # darwin-rebuild switch --flake ...#ungyo
nixup        # brew update + flake update + rebuild
```

---

## Bootstrap (fresh macOS machine)

If starting from scratch (no nix installed):

```bash
# Option A — Standard Nix (toyotama):
sh <(curl -L https://nixos.org/nix/install)

# Option B — Determinate installer (ungyo):
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Clone repo:
git clone git@github.com:verchalent/IsildursBane-Nix.git ~/src/IsildursBane-Nix

# Install nix-darwin (first time only):
nix run nix-darwin -- switch --flake ~/src/IsildursBane-Nix#<hostname>

# Subsequent rebuilds:
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#<hostname>
```
