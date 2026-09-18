{ ... }: {
  # Ungyo-only homebrew packages (M2 Mac Mini)

  homebrew = {
    onActivation = {
      autoUpdate = true; # Auto-update on mini (always on)
      upgrade = true;
      # "check" fails the switch (non-destructively) if undeclared packages
      # exist, instead of silently drifting or auto-removing on every
      # activation. Real removal happens via the `brewup` alias.
      cleanup = "check";
    };

    masApps = {
      WindowsApp = 1295203466; # RDP client — via MAS, not a cask (was cask on Ungyo-nix)
    };

    casks = [
      { name = "insta360-link-controller"; greedy = true; } # Insta360 webcam
    ];

    brews = [
      "netdata" # System monitoring (mini stays powered on)
    ];
  };
}
