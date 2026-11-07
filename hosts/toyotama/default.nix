{ config, pkgs, hostname, ... }: {
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/brew-common.nix
    ../../modules/darwin/brew-toyotama.nix
    ../../modules/darwin/mounts-toyotama.nix
  ];

  networking.hostName = "toyotama";

  # M4 MacBook Air — Caps Lock NOT remapped (all-keyboard mapping causes issues on external keyboards)
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = false;
  };

  # Firewall + stealth mode (laptop-specific; lulu also installed)
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  # Dock: Ghostty pinned (laptop primary terminal)
  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Ghostty.app"; }
    { app = "/System/Applications/System Settings.app"; }
    { app = "/System/Applications/Utilities/Activity Monitor.app"; }
  ];

  # SOPS: toyotama age key at standard path
  sops = {
    defaultSopsFile = ../../secrets/toyotama.yaml;
    age.keyFile = "/Users/justin/.config/sops/age/keys.txt";
    secrets.git_signing_key = { owner = "justin"; };
    secrets.pve_token       = { owner = "justin"; }; # Proxmox API token for pve-spice
    secrets.pve_ssh_target  = { owner = "justin"; }; # user@host for the pve-spice SSH tunnel
  };

  home-manager.users.justin = { imports = [
    ../../modules/home-manager/common/default.nix
    ../../modules/home-manager/toyotama/default.nix
  ]; };
}
