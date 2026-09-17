{ pkgs, hostname, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # autosuggestions + syntax-highlighting come from the antidote bundle
    # below instead, so the plugin isn't loaded twice.
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;

    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    initContent = ''
      eval "$(zellij setup --generate-auto-start zsh)"
      [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # antidote replaces oh-my-zsh / powerlevel10k
      export ZSH_CACHE_DIR="$HOME/.cache/zsh"
      mkdir -p "$ZSH_CACHE_DIR/completions"
      source "$(brew --prefix antidote)/share/antidote/antidote.zsh"
      antidote load "$HOME/.config/zsh/.zsh_plugins.txt"

      # starship replaces powerlevel10k
      eval "$(starship init zsh)"
    ''; # Zellij auto-start, cargo env, case-insensitive completion, antidote plugins, starship prompt

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
