{ ... }: {
  # Packages present on BOTH machines
  # Per-machine onActivation.autoUpdate set in host-specific brew files

  homebrew = {
    enable = true;
    global.brewfile = true;
    # caskArgs.no_quarantine intentionally omitted: `brew bundle` on Homebrew
    # 7.0.4 mis-translates it to `--no_quarantine` (underscore) when shelling
    # out to `brew install --cask`, which errors as an invalid option on any
    # fresh cask install. Redundant anyway — LaunchServices.LSQuarantine =
    # false (in common.nix) already disables Gatekeeper quarantine OS-wide.

    # Only Windows App from the Mac App Store (RDP client; not available as a cask).
    masApps = {
      WindowsApp = 1295203466;
    };

    # `greedy` is only set (in the host files) where brew must do the updating: apps that
    # claim auto-update but are not reliably updated by themselves. Everything else updates
    # itself, which also avoids brew replacing app bundles on every switch.
    casks = [
      "1password"                       # Password manager
      "1password-cli"                   # 1Password CLI
      "bartender"                       # Menu bar organizer
      "brave-browser"                   # Browser
      "claude-code"                     # Anthropic Claude CLI
      "ghostty"                         # Terminal emulator
      "lulu"                            # Outbound firewall
      "microsoft-edge"                  # Edge for M365
      "raycast"                         # Spotlight replacement
      "vorssaint"                       # GUI tweaks and misc tools
      "vcam"                            # Virtual camera
      "visual-studio-code"              # Editor
    ];

    brews = [
      "antidote"  # zsh plugin manager, replaces oh-my-zsh/p10k
      "awscli"    # Breaks when done nix-native
      "fzf"       # Nix version behind
      "mas"       # Mac App Store CLI
      "starship"  # Prompt, replaces powerlevel10k
      "uv"        # Python package manager
      "zellij"    # Terminal multiplexer; nix version behind
      "zoxide"    # Nix version behind
    ];
  };
}
