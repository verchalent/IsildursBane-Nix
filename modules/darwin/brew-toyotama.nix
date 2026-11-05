{ ... }: {
  # Toyotama-only homebrew packages (M4 MacBook Air)

  homebrew = {
    onActivation = {
      autoUpdate = false; # Manual update control on laptop
      upgrade = true;
      # "uninstall" removes any formula/cask not declared in this config on
      # every activation (app data is kept; "zap" would delete it too).
      cleanup = "uninstall";
    };

    masApps = {
      WindowsApp = 1295203466; # Suppress MAS update prompts
    };

    # virt-viewer (provides remote-viewer) is built natively for Apple Silicon
    # from this tap; the core `remoteviewer` cask is x86_64-only (needs Rosetta).
    taps = [ "jeffreywildman/virt-manager" ];

    casks = [
      { name = "alacritty";          greedy = true; } # Alt terminal
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
      "jeffreywildman/virt-manager/virt-viewer" # SPICE client (remote-viewer), used by pve-spice
      "squiid"     # TUI RPN calculator
      "tailscale"  # Tailscale CLI/daemon
    ];
  };
}
