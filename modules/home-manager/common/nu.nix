{ ... }: {
  # Nushell — disabled since 02-02-26 (broken config)
  # Re-enable when nushell config is fixed
  programs.nushell = {
    enable = true;
    configFile.source = ../dotfiles/config.nu;
  };
}
