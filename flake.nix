{
  description = "NixOS configuration for ebisu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; #may need to change in the future for darwin systems

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.ebisu = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit home-manager; };
      modules = [ ./hosts/ebisu ];
    };
  };
}
