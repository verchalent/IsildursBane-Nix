{ ... }: {
  # Packages present on BOTH machines
  # Per-machine onActivation.autoUpdate set in host-specific brew files

  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    global.brewfile = true;

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
      { name = "disk-inventory-x";   greedy = true; } # Disk usage visualizer
      { name = "ghostty";            greedy = true; } # Terminal emulator
      { name = "lulu";               greedy = true; } # Outbound firewall
      { name = "microsoft-edge";     greedy = true; } # Edge for M365
      { name = "raycast";            greedy = true; } # Spotlight replacement
      { name = "vcam";               greedy = true; } # Virtual camera
      { name = "visual-studio-code"; greedy = true; } # Editor
      { name = "windows-app";        greedy = true; } # RDP client
    ];

    brews = [
      "awscli"    # Breaks when done nix-native
      "curl"
      "fzf"       # Nix version behind
      "igrep"     # Grep replacement
      "mas"       # Mac App Store CLI
      "oh-my-posh" # Shell prompt for nushell
      "trippy"    # Network diagnostics
      "uv"        # Python package manager
      "zellij"    # Terminal multiplexer; nix version behind
      "zoxide"    # Nix version behind
    ];
  };
}
