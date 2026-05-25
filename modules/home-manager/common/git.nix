{ osConfig, ... }: {
  # Git config with SSH signing key sourced from SOPS secret (not hardcoded)
  # osConfig gives access to the darwin-level config including sops.secrets.*
  # The secret file contains the raw SSH public key string for the 1Password-backed key

  programs.git = {
    enable = true;
    settings = {
      user.name = "PestyLint";
      user.email = "me@example.com";
      push.autoSetupRemote = true;
      pull.rebase = true;
      fetch.prune = true;
      fetch.writeCommitGraph = true;
      branch.sort = "-committerdate";
      commit.gpgSign = true;
      tag.gpgSign = true;
      gpg.format = "ssh";
      # File path to sops-decrypted public key (avoids hardcoding key in any .nix file)
      user.signingKey = osConfig.sops.secrets.git_signing_key.path;
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
    includes = [
      { path = "~/.gitconfig.local"; }
    ];
  };
}
