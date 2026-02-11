{ config, pkgs, ... }:

{
  home.username = "pestilent";
  home.homeDirectory = "/home/pestilent";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
