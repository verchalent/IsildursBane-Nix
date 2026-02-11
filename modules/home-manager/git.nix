{ config, ... }: {
  programs.git = { # Nix was smashing git config. Added 03.25
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
      user.signingKey = builtins.readFile config.sops.secrets.onepassword_signing_key.path;
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
    includes = [
      { path = "~/.gitconfig.local"; }
    ];
  };
}
