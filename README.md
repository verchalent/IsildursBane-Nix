# IsildursBane-Nix

Unified nix-darwin / NixOS flake for all machines. Single source of truth — shared config in common modules, machine-specific differences isolated in host and module overlays.

## Hosts

| Hostname | Machine | OS | Notes |
|----------|---------|-----|-------|
| `toyotama` | M4 MacBook Air | nix-darwin | Full dev + media stack, stealth firewall |
| `ungyo` | M2 Mac Mini | nix-darwin | Server-oriented, Caps Lock → Escape, insta360 |

## Structure

```
flake.nix                          # Multi-system entry; mkDarwinSystem / mkNixosSystem helpers
.sops.yaml                         # age key recipients — one per machine
secrets/
  toyotama.yaml                    # Encrypted: toyotama SSH signing key (+ future secrets)
  ungyo.yaml                       # Encrypted: ungyo SSH signing key (+ future secrets)
hosts/
  toyotama/default.nix             # toyotama darwin config: keyboard, firewall, dock, sops
  ungyo/default.nix                # ungyo darwin config: keyboard, nix.enable=false, sops
modules/
  darwin/
    common.nix                     # Shared: system defaults, fonts, user, nix options
    brew-common.nix                # Homebrew packages on every darwin machine
    brew-toyotama.nix              # toyotama-only casks/brews
    brew-ungyo.nix                 # ungyo-only casks/brews
  home-manager/
    common/
      default.nix                  # Shared packages, programs, dotfile symlinks
      git.nix                      # Git + SSH signing via sops secret (no hardcoded key)
      zsh.nix                      # Zsh + aliases (nixswitch/nixup use hostname specialArg)
      tmux.nix                     # Tmux (identical across machines)
      nu.nix                       # Nushell (disabled — broken since 02-02-26)
    toyotama/default.nix           # Claude Code settings, pay-respects
    ungyo/default.nix              # ungyo-specific home additions (currently stub)
    dotfiles/                      # Dotfiles (alacritty, ghostty, nvim, zellij, etc.)
      claude/                      # Claude Code settings/statusline/skills (toyotama only)
    pwsh/                          # PowerShell profile + module lists
    scripts/
      fixMacOS.sh                  # Manual, not-yet-ported macOS defaults helper (run by hand)
scripts/
  nixup.sh                         # flake update + darwin-rebuild (called by nixup alias)
docs/
  hosts.md                         # Per-host first-time setup instructions
```

## Applying

```bash
# Rebuild current machine (hostname must match a darwinConfigurations key):
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#toyotama
darwin-rebuild switch --flake ~/src/IsildursBane-Nix#ungyo

# After first apply, aliases are available:
nixswitch    # darwin-rebuild switch for this machine
nixup        # brew update/upgrade/cleanup + flake update + rebuild
nixclean     # prune darwin + home-manager generations older than 30 days, then garbage-collect
nixdeepclean # prune all generations except the current one, then garbage-collect (more space, no rollback history)
```

## Secrets (SOPS + age)

SSH signing keys live in 1Password. The public keys are stored as sops-encrypted secrets, decrypted at activation — no key material in any `.nix` file.

`git.nix` references the decrypted key path via `osConfig.sops.secrets.git_signing_key.path`.

Each machine has its own age key (`~/.config/sops/age/keys.txt`) and its own secrets file. See [docs/hosts.md](docs/hosts.md) for per-host setup.

## Adding a New macOS Host

1. **Add host directory:**
   ```
   hosts/<newhostname>/default.nix
   ```
   Copy from an existing host. Set `networking.hostName`, `system.keyboard`, sops block, and `home-manager.users.justin` imports.

2. **Add machine-specific brew module** (if needed):
   ```
   modules/darwin/brew-<newhostname>.nix
   ```
   Import it from `hosts/<newhostname>/default.nix`.

3. **Add machine-specific home module** (if needed):
   ```
   modules/home-manager/<newhostname>/default.nix
   ```
   Import it in the host's `home-manager.users.justin`.

4. **Generate age key on the new machine:**
   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   grep "^# public" ~/.config/sops/age/keys.txt
   ```

5. **Update `.sops.yaml`** — add the new age public key and a creation rule:
   ```yaml
   - &newhostname age1...
   creation_rules:
     - path_regex: secrets/newhostname\.yaml$
       key_groups:
         - age:
           - *newhostname
   ```

6. **Create and encrypt secrets:**
   ```bash
   sops secrets/<newhostname>.yaml
   # add git_signing_key (SSH pubkey from 1Password), save to encrypt
   ```

7. **Register in `flake.nix`:**
   ```nix
   darwinConfigurations = {
     # ...existing...
     newhostname = mkDarwinSystem { hostname = "newhostname"; };
   };
   ```

8. **Apply:**
   ```bash
   darwin-rebuild switch --flake ~/src/IsildursBane-Nix#newhostname
   ```

## Adding a New Linux (NixOS) Host

1. **Add a `mkNixosSystem` helper to `flake.nix`** (stub already present as `nixosConfigurations = {}`):
   ```nix
   mkNixosSystem = { hostname, system ? "x86_64-linux" }:
     nixpkgs.lib.nixosSystem {
       inherit system;
       specialArgs = { inherit hostname; };
       modules = [
         sops-nix.nixosModules.sops
         home-manager.nixosModules.home-manager
         { home-manager.extraSpecialArgs = { inherit hostname; }; }
         ./hosts/${hostname}/default.nix
       ];
     };
   ```

2. **Add host directory:**
   ```
   hosts/<newhostname>/default.nix       # hardware, networking, users
   hosts/<newhostname>/hardware.nix      # generated via nixos-generate-config
   ```

3. **Add NixOS-specific modules** under `modules/nixos/` as needed (packages differ from darwin; no brew).

4. **Home-manager common modules are reusable** — but drop darwin-only settings (1Password SSH sign path, brew aliases). Pass overrides via the host's home-manager module.

5. **SOPS setup** is identical to macOS (steps 4–6 above). Use `sops-nix.nixosModules.sops` instead of `darwinModules`.

6. **Register in `flake.nix`:**
   ```nix
   nixosConfigurations = {
     newhostname = mkNixosSystem { hostname = "newhostname"; };
   };
   ```

7. **Apply:**
   ```bash
   sudo nixos-rebuild switch --flake ~/src/IsildursBane-Nix#newhostname
   ```
