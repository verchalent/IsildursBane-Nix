{ pkgs, ... }: {
  imports = [
    ./zsh.nix
    ./tmux.nix
    # ./nu.nix  # Disabled 02-02-26 (broken)
    ./git.nix
  ];

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    age          # age encryption (needed for sops key management)
    fd
    helix
    less
    lsd
    fastfetch
    neovim
    python3
    procs
    ripgrep
    sops         # CLI to encrypt/edit secrets/*.yaml (see docs/hosts.md)
    tealdeer
  ];

  home.sessionVariables = {
    PAGER = "less";
    CLICOLOR = 1;
    EDITOR = "nvim";
  };

  programs.atuin = {
    enable = true;
    # e2e_capture pty test times out in the nix sandbox (18.23.0)
    package = pkgs.atuin.overrideAttrs { doCheck = false; };
    enableZshIntegration = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "Dracula";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Dotfile symlinks (shared across all machines)
  home.file = {
    ".config/alacritty/alacritty.toml".source    = ../dotfiles/alacritty.toml;
    ".config/ghostty/config".source               = ../dotfiles/ghostty;
    ".config/nvim/init.vim".source                = ../dotfiles/nvim.rc;
    ".config/nvim/init.lua".source                = ../dotfiles/nvim-plugins.lua;
    ".config/zellij/config.kdl".source            = ../dotfiles/zellij.kdl;
    ".config/helix/config.toml".source            = ../dotfiles/helix.toml;
    ".config/direnv/direnvrc".source              = ../dotfiles/direnvrc;
    ".config/geany/colorschemes/retro.config".source = ../dotfiles/retro.conf;
    ".config/geany/geany.conf".source             = ../dotfiles/geany.conf;
    ".config/powershell/Microsoft.PowerShell_profile.ps1".source = ../pwsh/Microsoft.PowerShell_profile.ps1;
    ".config/powershell/modules_aws.txt".source   = ../pwsh/modules_aws.txt;
    ".config/powershell/modules.txt".source       = ../pwsh/modules.txt;
    ".config/starship.toml".source                = ../dotfiles/starship.toml;
    ".config/zsh/.zsh_plugins.txt".source         = ../dotfiles/zsh_plugins.txt;
    ".inputrc".source                             = ../dotfiles/inputrc;
  };
}
