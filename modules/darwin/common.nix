{ pkgs, ... }: {
  # Setting Reference: https://nix-darwin.github.io/nix-darwin/manual/index.html

  users.users.justin = {
    home = "/Users/justin";
    uid = 501;
  };

  programs.zsh.enable = true;

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = [ pkgs.coreutils ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  fonts.packages = [
    # Package names: https://github.com/NixOS/nixpkgs/blob/master/pkgs/data/fonts/nerd-fonts/manifests/fonts.json
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.meslo-lg
  ];

  system = {
    primaryUser = "justin";
    stateVersion = 6;

    defaults = {
      ActivityMonitor = {
        ShowCategory = 101; # All Processes, Hierarchically
      };

      dock = {
        autohide = true;
        launchanim = false;
        mouse-over-hilite-stack = true;
        mru-spaces = false;
        orientation = "left";
        show-recents = false;
        tilesize = 48;
        # persistent-apps set per-host
      };

      finder = {
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv"; # List view
        FXRemoveOldTrashItems = true;
        NewWindowTarget = "Home";
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = true;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = true;
        ShowStatusBar = true;
      };

      LaunchServices.LSQuarantine = false; # Disable app quarantine (compensated by lulu + firewall)

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 14;
        KeyRepeat = 1;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.sound.beep.volume" = 0.000;
        "com.apple.swipescrolldirection" = false; # Disable natural scrolling
        "com.apple.mouse.tapBehavior" = 1; # Tap to click
        NSDocumentSaveNewDocumentsToCloud = false;
      };

      spaces.spans-displays = false;

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
      };

      menuExtraClock.Show24Hour = true;

      loginwindow = {
        DisableConsoleAccess = true;
        GuestEnabled = false;
        SHOWFULLNAME = false;
      };

      WindowManager = {
        EnableStandardClickToShowDesktop = false;
        StageManagerHideWidgets = true;
      };
    };
  };
}
