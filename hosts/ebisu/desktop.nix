{ config, pkgs, ... }:

{
  # X11 & Display Manager
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KDE dark mode
  qt.style = "breeze";
  environment.variables.QT_QUICK_CONTROLS_STYLE = "org.kde.breeze";
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings."org/kde/kdeglobals/General".ColorScheme = "BreezeDark";
    settings."org/kde/kdeglobals/KDE".LookAndFeelPackage = "org.kde.breezedark.desktop";
  }];

  # RDP via xrdp
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true;
  };

  # Audio (pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing
  services.printing.enable = false;
}
