{ pkgs, hostname, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      eval "$(zellij setup --generate-auto-start zsh)"
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      . "$HOME/.cargo/env"
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    ''; # Zellij auto-start, p10k, cargo env, case-insensitive completion

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    localVariables = {
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD = true;
      ZSH_THEME = "powerlevel10k/powerlevel10k";
    };

    shellAliases = {
      brewup    = "brew update && brew upgrade && brew cleanup --prune=all";
      cat       = "bat";
      cd        = "z";
      explorer  = "open";
      find      = "fd";
      la        = "lsd -la";
      ll        = "lsd -l";
      ls        = "lsd";
      # hostname specialArg ensures each machine rebuilds its own configuration
      nixswitch = "darwin-rebuild switch --flake ~/src/IsildursBane-Nix#${hostname}";
      nixup     = "brewup; pushd ~/src/IsildursBane-Nix; nix flake update && sudo darwin-rebuild switch --flake ~/src/IsildursBane-Nix#${hostname}; popd";
      nixclean  = "nix-store --gc";
      powershell = "pwsh";
      ps        = "procs";
      ssh       = "TERM=xterm-256color /usr/bin/ssh"; # Fix terminal type for alacritty/ghostty
      vi        = "hx";
    };
  };
}
