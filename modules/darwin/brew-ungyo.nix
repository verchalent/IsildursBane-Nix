{ ... }: {
  # Ungyo-only homebrew packages (M2 Mac Mini)

  homebrew = {
    onActivation = {
      autoUpdate = true; # Auto-update on mini (always on)
      upgrade = true;
      # "uninstall" removes any formula/cask not declared in this config on
      # every activation (app data is kept; "zap" would delete it too).
      cleanup = "uninstall";
    };

    casks = [
      "insta360-link-controller"        # Insta360 webcam
    ];

    brews = [
      "netdata" # System monitoring (mini stays powered on)
    ];
  };
}
