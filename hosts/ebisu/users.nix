{ config, pkgs, ... }:

{
  # Users
  users.users.pestilent = {
    isNormalUser = true;
    description = "pestilent";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Browsers
  programs.firefox.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
  ];
}
