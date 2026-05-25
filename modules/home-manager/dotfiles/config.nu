# config.nu

# Initial nu configuration file.

# =============================================================================
# Env Configuration
# =============================================================================
$env.config.show_banner = false
$env.config.buffer_editor = "hx"
oh-my-posh init nu --config ~/src/Toyotama-Nix/modules/home-manager/dotfiles/ohmyposh-nu.json


# =============================================================================
# Direnv
# =============================================================================
$env.config = {
  hooks: {
    pre_prompt: [{ ||
      if (which direnv | is-empty) {
        return
      }

      direnv export json | from json | default {} | load-env
      if 'ENV_CONVERSIONS' in $env and 'PATH' in $env.ENV_CONVERSIONS {
        $env.PATH = do $env.ENV_CONVERSIONS.PATH.from_string $env.PATH
      }
    }]
  }
}

# =============================================================================
# Zoxide
# =============================================================================

# Initialize hook to add new entries to the database.
if (not ($env | default false __zoxide_hooked | get __zoxide_hooked)) {
  $env.__zoxide_hooked = true
  $env.config = ($env | default {} config).config
  $env.config = ($env.config | default {} hooks)
  $env.config = ($env.config | update hooks ($env.config.hooks | default {} env_change))
  $env.config = ($env.config | update hooks.env_change ($env.config.hooks.env_change | default [] PWD))
  $env.config = ($env.config | update hooks.env_change.PWD ($env.config.hooks.env_change.PWD | append {|_, dir|
    zoxide add -- $dir
  }))
}

# Jump to a directory using only keywords.
def --env __zoxide_z [...rest:string] {
  let arg0 = ($rest | append '~').0
  let path = if (($rest | length) <= 1) and ($arg0 == '-' or ($arg0 | path expand | path type) == dir) {
    $arg0
  } else {
    (zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n")
  }
  cd $path
}

# Jump to a directory using interactive search.
def --env __zoxide_zi [...rest:string] {
  cd $'(zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}


# =============================================================================
# Aliases
# =============================================================================

alias z = __zoxide_z
alias zi = __zoxide_zi
# alias brew = 'env PATH="${PATH//$(pyenv root)\/shims:/}" brew'# Not valid?
alias cat = bat
alias cd = z
alias docker = podman
alias explorer = xdg-open
alias find = fd
alias vi = hx
alias nu-open = open
alias open = ^open
alias powershell = pwsh

def ll [] { ls --long | select mode user group size created modified accessed name }
def la [] { ls --all --long | select mode user group size created modified accessed name }
def brewup [] { brew update ; brew upgrade ; brew cleanup --prune=all}
def nixup [] { brewup; cd ~/src/Ungyo-nix; ./modules/home-manager/scripts/nixup.sh } #no push/pop need to fix
def nixclean [] { nix-store --gc }
def ssh [] { TERM=xterm-256color /usr/bin/ssh }