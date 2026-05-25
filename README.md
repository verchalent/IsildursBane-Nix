# IsildursBane-Nix

Unified nix-darwin flake for all Apple Silicon Macs.

| Host | Machine | Notes |
|------|---------|-------|
| `toyotama` | M4 MacBook Air | Full dev + media stack, stealth firewall |
| `ungyo` | M2 Mac Mini | Server-oriented, Caps Lock → Escape |

## Structure

```
flake.nix                          # Multi-system entry point
.sops.yaml                         # age key recipients per machine
secrets/
  toyotama.yaml                    # Encrypted: toyotama git signing key
  ungyo.yaml                       # Encrypted: ungyo git signing key
hosts/{toyotama,ungyo}/default.nix # Per-machine darwin config + sops setup
modules/darwin/
  common.nix                       # Shared: system defaults, fonts, user
  brew-common.nix                  # Homebrew packages on all machines
  brew-{toyotama,ungyo}.nix        # Machine-specific packages
modules/home-manager/
  common/                          # Shared: packages, git, zsh, tmux
  {toyotama,ungyo}/                # Machine-specific home config
  dotfiles/                        # Shared dotfiles (alacritty, nvim, zellij, etc.)
  pwsh/                            # PowerShell profile + module lists
```

## Applying

```bash
# On toyotama:
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#toyotama

# On ungyo:
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#ungyo

# Via alias (after first apply sets up zsh aliases):
nixswitch   # rebuild current machine
nixup       # brew update + flake update + rebuild
nixclean    # nix-store --gc
```

## Secrets Setup (SOPS + age)

SSH signing keys (stored in 1Password) are managed via sops-nix — no raw keys in nix files.

### Toyotama (first-time)

The age key already exists. Just encrypt the secrets file:

```bash
# Verify age key exists:
cat ~/.config/sops/age/keys.txt

# Edit + encrypt toyotama secrets:
cd ~/src/IsildursBane-Nix
sops secrets/toyotama.yaml
# The file in secrets/ is a plaintext template; sops will encrypt on save.
```

### Ungyo (first-time)

```bash
# 1. Generate age key on Ungyo:
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
grep "^# public" ~/.config/sops/age/keys.txt  # copy this value

# 2. Update .sops.yaml: replace <UNGYO_AGE_PUBLIC_KEY> with the value above

# 3. Create SSH signing key in 1Password for Ungyo (new key item)
#    Get the public key from 1Password

# 4. Fill in and encrypt ungyo secrets:
sops secrets/ungyo.yaml  # add the SSH public key, save to encrypt

# 5. Apply:
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#ungyo
```

## Bootstrap (fresh machine)

```bash
# Install nix (determinate installer on ungyo, standard on toyotama):
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Install nix-darwin:
nix run nix-darwin -- switch --flake ~/src/IsildursBane-Nix#<hostname>

# Subsequent rebuilds:
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#<hostname>
```

## Key Design Decisions

- **SSH signing key in SOPS**: `git.nix` references `osConfig.sops.secrets.git_signing_key.path` — the sops-decrypted file path. No key material in any `.nix` file.
- **Per-machine secrets**: Each machine has its own age key and secrets file. Toyotama and Ungyo have different SSH signing keys in 1Password.
- **`hostname` specialArg**: Flows from `flake.nix` → `specialArgs` (darwin) + `extraSpecialArgs` (home-manager). Used in `zsh.nix` for `nixswitch`/`nixup` aliases.
- **brew-common + brew-{host}**: Homebrew config merges across modules. Common packages + MAS apps on all machines; host-specific additions layered on top.
- **Linux stub**: `nixosConfigurations = {}` in `flake.nix` — add Linux hosts when needed without restructuring.
