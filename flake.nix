{
  description = "IsildursBane — unified nix-darwin flake (toyotama + ungyo)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, darwin, sops-nix, ... }:
  let
    mkDarwinSystem = { hostname, system ? "aarch64-darwin" }:
      darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit hostname; };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          sops-nix.darwinModules.sops
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit hostname; };
          }
          ./hosts/${hostname}/default.nix
        ];
      };
  in {
    darwinConfigurations = {
      toyotama = mkDarwinSystem { hostname = "toyotama"; };
      ungyo    = mkDarwinSystem { hostname = "ungyo"; };
    };

    # Stub: Linux hosts added here when needed
    nixosConfigurations = {};
  };
}
