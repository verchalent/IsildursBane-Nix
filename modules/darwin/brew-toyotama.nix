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

    casks = [
      { name = "amazon-workspaces";  greedy = true; } # AWS WorkSpaces client (toyotama-only)
      "geany"                           # Notepad++ replacement
      "keyclu"                          # Keyboard shortcut hints
      "Netiquette"                      # Objective-See socket monitor
      "notunes"                         # Disable iTunes
      "obsidian"                        # Second brain
      "powershell"                      # PowerShell
      "signal"                          # Signal messenger
      "spotify"                         # Music
      { name = "tailscale-app";      greedy = true; } # Tailscale VPN GUI
      "TaskExplorer"                    # Objective-See process explorer
      "wavebox"                         # Webapp container
      "wifiman"                         # Ubiquiti WiFi + VPN
      { name = "wireshark-app";      greedy = true; } # Packet analysis
    ];

    brews = [
      "node"       # Node.js
      "p0f"        # Passive OS fingerprinting
      "sherlock"   # OSINT username search
      "squiid"     # TUI RPN calculator
    ];
  };
}
