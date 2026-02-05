# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git direnv fzf-tab vi-mode)

# Needed for just autocomplete, but will pull in all of brew
# https://github.com/casey/just#shell-completion-scripts
# Init Homebrew, which adds environment variables
eval "$(brew shellenv)"
# Add Homebrew's site-functions to fpath
fpath=($(brew --prefix)/share/zsh/site-functions $fpath)

source $ZSH/oh-my-zsh.sh

# User configuration

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="$EDITOR ~/.zshrc"
alias ohmyzsh="$EDITOR  ~/.oh-my-zsh"
alias zshconfig="$EDITOR ~/.zshrc"
alias nvimconfig="$EDITOR ~/.config/nvim"
alias rezsh="source ~/.zprofile && source ~/.zshrc"
alias config='/usr/bin/git --git-dir=/Users/scarab5q/.cfg/ --work-tree=/Users/scarab5q'
alias lazyconfig='lazygit --git-dir=$HOME/.cfg --work-tree=$HOME'
alias lc='lazygit --git-dir=$HOME/.cfg --work-tree=$HOME'
alias lg='lazygit'
alias branches='git branch | grep -v "^\*" | fzf --height=20% --reverse --info=inline | xargs git checkout'
alias dall='direnv allow'
alias dedit='direnv edit'
alias rd='~/repos/arrow/scripts/start-docker.sh'
alias rdb='~/repos/arrow/scripts/start-docker.sh --build'
alias dockerstopall='docker stop $(docker ps -q) && docker rm $(docker ps -aq)'
alias lzd='lazydocker'
alias ghd='gh dash'
alias jed='just --edit'
alias ls='eza'

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"

# bun completions
[ -s "/Users/scarab5q/.bun/_bun" ] && source "/Users/scarab5q/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

cf() { 
  /usr/bin/git --git-dir=/Users/scarab5q/.cfg/ --work-tree=/Users/scarab5q ls-tree --full-tree -r --full-name HEAD --format $HOME'/%(path)' | fzf -m --preview='bat --color=always {}' --bind 'enter:become(nvim {+})'; 
}
if [[ $TERM_PROGRAM == iTerm.app ]] 
then
  eval "$(zellij setup --generate-auto-start zsh)"
fi

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

source /Users/scarab5q/.config/broot/launcher/bash/br

function aws-mfa() {
  local base_profile="default"
  local region="eu-west-2"
  local duration="43200"
  local serial=""
  local code out ak sk tok exp

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b) base_profile="$2"; shift 2 ;;
      -r) region="$2"; shift 2 ;;
      -d) duration="$2"; shift 2 ;;
      -s) serial="$2"; shift 2 ;;
      -h|--help)
        echo "usage: aws-mfa [-b baseProfile] [-r region] [-d durationSeconds] [-s mfaSerialArn]" >&2
        return 0
        ;;
      *) echo "Unknown arg: $1" >&2; return 2 ;;
    esac
  done

  command -v aws >/dev/null || { echo "aws not found" >&2; return 1; }
  command -v python3 >/dev/null || { echo "python3 not found" >&2; return 1; }

  if [[ -z "$serial" ]]; then
    serial="$(aws iam list-mfa-devices --profile "$base_profile" --query 'MFADevices[0].SerialNumber' --output text 2>/dev/null)"
    [[ -n "$serial" && "$serial" != "None" ]] || { echo "No MFA device found; pass -s <mfa-serial-arn>" >&2; return 1; }
  fi

  # zsh read prompt differs from bash
  if [[ -n "${ZSH_VERSION-}" ]]; then
    read -r "code?MFA code for $serial: "
  else
    read -r -p "MFA code for $serial: " code
  fi

  out="$(aws sts get-session-token \
    --profile "$base_profile" \
    --serial-number "$serial" \
    --token-code "$code" \
    --duration-seconds "$duration" 2>/dev/null)" || {
      echo "Failed to get session token (bad MFA code? missing permission? wrong profile?)" >&2
      return 1
    }

  ak="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["AccessKeyId"])' <<<"$out")"
  sk="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["SecretAccessKey"])' <<<"$out")"
  tok="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["SessionToken"])' <<<"$out")"
  exp="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["Credentials"]["Expiration"])' <<<"$out")"

  export AWS_ACCESS_KEY_ID="$ak"
  export AWS_SECRET_ACCESS_KEY="$sk"
  export AWS_SESSION_TOKEN="$tok"
  export AWS_REGION="$region"
  export AWS_DEFAULT_REGION="$region"
  export AWS_MFA_SESSION_EXPIRATION="$exp"

  echo "AWS MFA session active (expires: $exp)"
}



