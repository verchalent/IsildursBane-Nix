{ pkgs, ... }: {
  # Toyotama-only home-manager config (M4 MacBook Air)

  # pay-respects: "thefuck" successor — corrects previous console commands
  # Installed+configured via programs module (no separate home.packages entry needed)
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
  };

  # Claude Code settings (laptop only — claude-code cask installed on toyotama)
  home.file = {
    ".claude/settings.json".source  = ../dotfiles/claude/settings.json;
    ".claude/statusline.sh".source  = ../dotfiles/claude/statusline.sh;
    ".claude/skills".source         = ../dotfiles/claude/skills;
  };
}
