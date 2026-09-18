{ ... }: {
  # Toyotama-only homebrew packages (M4 MacBook Air)

  homebrew = {
    onActivation = {
      autoUpdate = false; # Manual update control on laptop
      upgrade = true;
      # "check" fails the switch (non-destructively) if undeclared packages
      # exist, instead of silently drifting or auto-removing on every
      # activation. Real removal happens via the `brewup` alias.
      cleanup = "check";
    };

    masApps = {
      WindowsApp = 1295203466; # Suppress MAS update prompts
    };

    casks = [
      { name = "alacritty";          greedy = true; } # Alt terminal
      { name = "alcove";             greedy = true; } # Notch util
      { name = "amazon-workspaces";  greedy = true; } # AWS WorkSpaces client (toyotama-only)
      { name = "docker-desktop";     greedy = true; } # Docker daemon
      { name = "geany";              greedy = true; } # Notepad++ replacement
      { name = "keyclu";             greedy = true; } # Keyboard shortcut hints
      { name = "Netiquette";         greedy = true; } # Objective-See socket monitor
      { name = "notunes";            greedy = true; } # Disable iTunes
      { name = "obsidian";           greedy = true; } # Second brain
      { name = "postman";            greedy = true; } # API testing
      { name = "powershell";         greedy = true; } # PowerShell
      { name = "signal";             greedy = true; } # Signal messenger
      { name = "spotify";            greedy = true; } # Music
      { name = "synology-drive";     greedy = true; } # Cloud drive
      { name = "tailscale-app";      greedy = true; } # Tailscale VPN GUI
      { name = "TaskExplorer";       greedy = true; } # Objective-See process explorer
      { name = "wavebox";            greedy = true; } # Webapp container
      { name = "whisky";             greedy = true; } # Wine bottles for macOS
      { name = "wifiman";            greedy = true; } # Ubiquiti WiFi + VPN
      { name = "wireshark-app";      greedy = true; } # Packet analysis
    ];

    brews = [
      "lazydocker" # Docker TUI
      "lazygit"    # Git TUI
      "node"       # Node.js
      "p0f"        # Passive OS fingerprinting
      "sherlock"   # OSINT username search
      "squiid"     # TUI RPN calculator
      "tailscale"  # Tailscale CLI/daemon
    ];
  };
}
