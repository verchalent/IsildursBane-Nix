{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    historyLimit = 5000;
    clock24 = true;
    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
    ];
  };
}
