{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ./desktop.nix
    ./networking.nix
    ./users.nix
    ../../modules/home-manager
  ];

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hostname
  networking.hostName = "ebisu";

  # Home-manager user mapping (username + homeDirectory are host-specific)
  home-manager.users.pestilent = import ../../modules/home-manager/pestilent.nix;

  system.stateVersion = "25.11";
}
