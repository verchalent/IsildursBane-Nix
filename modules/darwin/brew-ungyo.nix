{ ... }: {
  # Ungyo-only homebrew packages (M2 Mac Mini)

  homebrew = {
    onActivation = {
      autoUpdate = true; # Auto-update on mini (always on)
      upgrade = true;
      cleanup = "uninstall";
    };

    casks = [
      { name = "insta360-link-controller"; greedy = true; } # Insta360 webcam
    ];

    brews = [
      "netdata" # System monitoring (mini stays powered on)
    ];
  };
}
