{ config, osConfig, lib, pkgs, ... }: {
  # Toyotama-only home-manager config (M4 MacBook Air)

  # pay-respects: "thefuck" successor — corrects previous console commands
  # Installed+configured via programs module (no separate home.packages entry needed)
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
  };

  # pve-spice: Proxmox SPICE console launcher (needs the remoteviewer cask, see brew-toyotama.nix)
  home.packages = [
    (import ../scripts/pve-spice.nix {
      inherit pkgs;
      host = "192.168.1.248";
      tokenFile = osConfig.sops.secrets.pve_token.path;
    })
  ];

  # Claude Code settings (laptop only — claude-code cask installed on toyotama)
  home.file = {
    ".claude/settings.json".source  = ../dotfiles/claude/settings.json;
    ".claude/statusline.sh".source  = ../dotfiles/claude/statusline.sh;
    ".claude/skills".source         = ../dotfiles/claude/skills;

    # ~/Documents lives on the NAS (autofs mount from modules/darwin/mounts-toyotama.nix)
    "Documents".source = config.lib.file.mkOutOfStoreSymlink "/mnt/Nirankar/homes/pestilent/Documents";
  };

  # macOS recreates ~/Documents as a real dir; remove it if empty so the symlink can be placed.
  # rmdir refuses non-empty dirs, in which case checkLinkTargets aborts rather than clobbering.
  home.activation.removeEmptyDocuments = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -d "$HOME/Documents" ] && [ ! -L "$HOME/Documents" ]; then
      run rmdir "$HOME/Documents" 2>/dev/null || true
    fi
  '';
}
