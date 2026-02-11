{ config, pkgs, ... }:

{
  # NetworkManager
  networking.networkmanager.enable = true;

  # Firewall
  networking.firewall.allowedTCPPorts = [ 22 3389 ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
