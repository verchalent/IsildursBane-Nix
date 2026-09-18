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

    masApps = {
      Keynote    = 409183694;
      iMovie     = 408981434;
      Pages      = 409201541;
      GarageBand = 682658836;
      Numbers    = 409203825;
    };

    taps = [
      "fujiapple852/trippy"
      {
        name = "konradsz/igrep";
        clone_target = "https://github.com/konradsz/igrep.git";
        force_auto_update = true;
      }
    ];

    casks = [
      { name = "1password";          greedy = true; } # Password manager
      { name = "1password-cli";      greedy = true; } # 1Password CLI
      { name = "alt-tab";            greedy = true; } # Windows-style Cmd+Tab
      { name = "bartender";          greedy = true; } # Menu bar organizer
      { name = "brave-browser";      greedy = true; } # Browser
    #  { name = "disk-inventory-x";   greedy = true; } # Disk usage visualizer
      { name = "ghostty";            greedy = true; } # Terminal emulator
      { name = "lulu";               greedy = true; } # Outbound firewall
      { name = "microsoft-edge";     greedy = true; } # Edge for M365
      { name = "raycast";            greedy = true; } # Spotlight replacement
      { name = "vcam";               greedy = true; } # Virtual camera
      { name = "visual-studio-code"; greedy = true; } # Editor
      # Windows App: installed via masApps.WindowsApp (toyotama), not a cask —
      # avoids two copies of the same app.
    ];

    brews = [
      "antidote"  # zsh plugin manager, replaces oh-my-zsh/p10k
      "awscli"    # Breaks when done nix-native
      "curl"
      "fzf"       # Nix version behind
      "igrep"     # Grep replacement
      "mas"       # Mac App Store CLI
      "starship"  # Prompt, replaces powerlevel10k
      "trippy"    # Network diagnostics
      "uv"        # Python package manager
      "zellij"    # Terminal multiplexer; nix version behind
      "zoxide"    # Nix version behind
    ];
  };
}
