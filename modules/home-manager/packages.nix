{ pkgs, ... }: {
  home.packages = with pkgs; [
    age
    curl
    fd
    helix
    less
    lsd
    mpv
    neofetch
    neovim
    podman
    python3
    procs
    ripgrep
    tealdeer
    vimPlugins.tmux-nvim
    zellij
    zsh-powerlevel10k
  ];
}