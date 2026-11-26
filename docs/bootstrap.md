# bootstrap-darwin.sh

Takes a fresh Mac from "repo cloned" to "fully conformed" with the config for one host.
Runbook (the manual steps before it and after it): [hosts.md](hosts.md#new-mac-blank-to-conformed).

```bash
scripts/bootstrap-darwin.sh --check <host>   # read-only preflight, changes nothing
scripts/bootstrap-darwin.sh <host>           # the real run
scripts/bootstrap-darwin.sh --yes <host>     # same, skipping the y/N questions
```

`<host>` must be a `darwinConfigurations` name in `flake.nix` (`toyotama`, `ungyo`, `okuninushi`).
Every phase is safe to repeat: if something fails, fix it and run the script again.

## Before it runs: what you need
macOS on Apple silicon, Command Line Tools (`xcode-select --install`, gives `git`), the repo cloned,
an App Store sign-in, about 30 GiB free, network access. Nothing else: no Homebrew, Nix or 1Password.

## What it does, in order

**1. Preflight (read-only).** Collects *every* problem and prints them together, then stops before
changing anything. Checks: macOS + arm64, not root, Command Line Tools present, `hosts/<host>` exists,
the host is registered in `flake.nix` and has a key in `.sops.yaml`, 30 GiB free, github.com and
cache.nixos.org reachable, git can reach `origin`, and (asks you) that the App Store is signed in
(that cannot be checked automatically). `--check` stops here.

**2. Administrator access.** Asks for your password once (`sudo -v`) and keeps it alive for the run.

**3. Homebrew.** Installs it if `/opt/homebrew/bin/brew` is missing. nix-darwin manages casks and
brews but does not install Homebrew itself.

**4. Nix.** Installs it with the Determinate installer if `nix` is missing (flakes enabled by default).

**5. age key.** Creates `~/.config/sops/age/keys.txt` if missing. This is the machine's key for
decrypting `secrets/<host>.yaml`. It cannot be recovered: keep a copy (1Password later).

**6. Secrets gate.** Proves this machine can decrypt `secrets/<host>.yaml` *before* the long step.
- Decrypts fine: done.
- File missing or encrypted to another machine's key, and it holds only `git_signing_key`: the script
  puts this machine's age public key into `.sops.yaml`, asks for the SSH signing public key (Enter
  skips it; set it later with `sops secrets/<host>.yaml`), re-encrypts, and commits **locally**.
- File holds other secrets (NAS login, tokens): it stops and tells you to re-key from a machine that
  can still decrypt (`sops updatekeys`), because those values cannot be re-created here.

**7. Hostname.** Sets HostName, LocalHostName and ComputerName to `<host>` (the flake name must match).

**8. /etc cleanup.** Renames the stock `/etc/bashrc` and `/etc/zshrc` to `*.before-nix-darwin`;
nix-darwin refuses to overwrite them otherwise. Nothing is lost.

**9. First switch.** `darwin-rebuild switch --flake .#<host>` (via `nix run nix-darwin` the first
time). This is the long step (20 to 60 min): the Nix store, then every cask, brew and App Store app,
including 1Password.

At the end it prints how long each phase took.

## What it does NOT do
Push the secrets commit, sign in to 1Password/Tailscale/browsers, approve system extensions
(LuLu, Tailscale) or grant Accessibility/Screen Recording. Those are in hosts.md under
"After the switch".
