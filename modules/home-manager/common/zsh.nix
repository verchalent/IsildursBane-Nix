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
      # bundle cleanup uninstalls anything not declared in the Nix-generated
      # Brewfile (HOMEBREW_BUNDLE_FILE, set by homebrew.global.brewfile); plain
      # cleanup then prunes old cached versions of what's left.
      brewup    = "brew update && brew upgrade && brew bundle cleanup --force && brew cleanup --prune=all";
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
      # Plain `nix-store --gc` reclaims almost nothing: every kept generation
      # is its own GC root, so anything it references reads as "in use".
      # These prune generations first (unrooting old closures), then collect
      # garbage. Neither ever touches the *current* generation, so you can't
      # GC your way into an unbootable system.
      #
      # nixclean: safe/routine — drops darwin + home-manager generations
      # older than 30 days, keeps recent rollback history.
      nixclean  = "sudo nix-env --delete-generations 30d --profile /nix/var/nix/profiles/system && nix-env --delete-generations 30d --profile ~/.local/state/nix/profiles/home-manager && sudo nix-collect-garbage -d";
      # nixdeepclean: aggressive — drops every generation except the one
      # currently active. Use when you want the space back and don't need
      # to roll back past today.
      nixdeepclean = "sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system && nix-env --delete-generations old --profile ~/.local/state/nix/profiles/home-manager && sudo nix-collect-garbage -d";
      powershell = "pwsh";
      ps        = "procs";
      ssh       = "TERM=xterm-256color /usr/bin/ssh"; # Fix terminal type for alacritty/ghostty
      vi        = "hx";
    };
  };
}
