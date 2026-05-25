{ config, pkgs, hostname, ... }: {
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/brew-common.nix
    ../../modules/darwin/brew-ungyo.nix
  ];

  networking.hostName = "ungyo";

  # M2 Mac Mini — Caps Lock → Escape
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # Determinate Nix installer: disable nix-darwin's built-in daemon management
  nix.enable = false;

  # Dock: Ghostty pinned (mini primary terminal)
  system.defaults.dock.persistent-apps = [
    { app = "/Applications/Ghostty.app"; }
    { app = "/System/Applications/System Settings.app"; }
    { app = "/System/Applications/Utilities/Activity Monitor.app"; }
  ];

  # SOPS: ungyo age key at standard path
  sops = {
    defaultSopsFile = ../../secrets/ungyo.yaml;
    age.keyFile = "/Users/justin/.config/sops/age/keys.txt";
    secrets.git_signing_key = { owner = "justin"; };
  };

  home-manager.users.justin = { imports = [
    ../../modules/home-manager/common/default.nix
    ../../modules/home-manager/ungyo/default.nix
  ]; };
}
