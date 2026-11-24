{ config, pkgs, hostname, ... }: {
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/brew-common.nix
    ../../modules/darwin/brew-okuninushi.nix
    # Enable after secrets/okuninushi.yaml holds nas_smb_host/user/password (sops secrets/okuninushi.yaml):
    # ../../modules/darwin/mounts-nas.nix
  ];

  networking.hostName = "okuninushi";

  # M6 Mac Mini (replaces ungyo, M2) — Caps Lock → Escape
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

  # SOPS: okuninushi age key at standard path
  sops = {
    defaultSopsFile = ../../secrets/okuninushi.yaml;
    age.keyFile = "/Users/justin/.config/sops/age/keys.txt";
    secrets.git_signing_key = { owner = "justin"; };
  };

  home-manager.users.justin = { imports = [
    ../../modules/home-manager/common/default.nix
    ../../modules/home-manager/okuninushi/default.nix
  ]; };
}
