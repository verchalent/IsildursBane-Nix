{ home-manager, ... }:

{
  imports = [ 
    home-manager.nixosModules.home-manager 
    ./dotfiles.nix
    ./git.nix
    ./packages.nix
    ./programs.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
}
