# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

export GPG_TTY=$(tty)



# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""

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

# jj dynamic completions (bookmarks, revisions, files)
source <(COMPLETE=zsh jj)

# Record mtimes of shell config at source time; prompt flags staleness if either changes.
typeset -g ZSHRC_MTIME=$(stat -f %m ~/.zshrc 2>/dev/null)
typeset -g ZPROFILE_MTIME=$(stat -f %m ~/.zprofile 2>/dev/null)

_zshrc_stale_info() {
  local stale=()
  local cur
  cur=$(stat -f %m ~/.zshrc 2>/dev/null)
  [[ -n $cur && $cur != $ZSHRC_MTIME ]] && stale+=("zshrc")
  cur=$(stat -f %m ~/.zprofile 2>/dev/null)
  [[ -n $cur && $cur != $ZPROFILE_MTIME ]] && stale+=("zprofile")
  (( ${#stale} == 0 )) && return
  print -n "%{$fg_bold[yellow]%}⟳${(j:,:)stale}%{$reset_color%} "
}

# starship prompt — shows git AND jj info side-by-side (see ~/.config/starship.toml)
eval "$(starship init zsh)"
PROMPT='$(_zshrc_stale_info)'"$PROMPT"

# User configuration

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

export EDITOR='hx'

# Cached 1Password secrets — interactive-shell only. Background non-interactive
# shells (scripts, hooks, `bash -c`) don't need these. The file is the plain
# `export` output of ~/scripts/refresh-secrets; re-run that script to refresh.
[ -f ~/.secrets ] && source ~/.secrets

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
alias handoff='~/scripts/handoff.sh'
alias ls='eza'
alias zr='zellij run --'
alias ecl="emacsclient -a '' -c"
alias j='just'
alias ded='direnv edit'
alias npm="sfw npm"
alias pnpm="sfw pnpm"
# alias bun="sfw bun"
alias mcd="mkdir -p "$1" && cd "$1";"

# Fetch secrets from 1Password and cache them in ~/.secrets
# Run this once after login or when secrets rotate — avoids Touch ID on every shell
refresh-secrets() {
  echo "Fetching secrets from 1Password (Touch ID required)..."
  local openai_key
  openai_key=$(op item get 5vjtbazh33oddjbodlkjbhifvi --fields password --reveal) || { echo "Failed to fetch from 1Password"; return 1; }

  # Remove old cached value and append new one
  sed -i '' '/^export OPENAI_API_KEY=/d' ~/.secrets
  echo "export OPENAI_API_KEY=\"$openai_key\"" >> ~/.secrets

  # Reload into current shell
  source ~/.secrets
  echo "Secrets refreshed and cached in ~/.secrets"
}
alias simcopy='pbpaste | xcrun simctl pbcopy booted'
alias simpaste='xcrun simctl pbpaste booted | pbcopy'
alias checkai='$EDITOR /tmp/run.sh'
alias runai='chmod +x /tmp/run.sh && /tmp/run.sh'
# alias claude='claude --dangerously-load-development-channels server:neovim-yank'
alias jjst='jj st'
alias jst='jj st'
alias jdev='just dev'

function ebancopy() {
  egiban
  simcopy
}

eval "$(direnv hook zsh)"
eval "$(zoxide init zsh)"

# bun completions
[ -s "/Users/scarab5q/.bun/_bun" ] && source "/Users/scarab5q/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Auto-switch node version when entering a directory with .nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# mise: activates per-project tool versions when a mise.toml / mise.local.toml is present.
# Loaded after nvm so mise wins inside mise-managed directories; nvm keeps owning everywhere else.
eval "$(mise activate zsh)"

cf() {
  /usr/bin/git --git-dir=/Users/scarab5q/.cfg/ --work-tree=/Users/scarab5q ls-tree --full-tree -r --full-name HEAD --format $HOME'/%(path)' | fzf -m --preview='bat --color=always {}' --bind 'enter:become(nvim {+})'
}

# fzf shell integration: Ctrl+T (files), Ctrl+R (history), Alt+C (cd)
source <(fzf --zsh)

# frf — fzf-find a file in the current repo and open it in nvim.
# Works in either jj or git repos; falls back to cwd if neither.
# (Named to avoid clashing with omz git plugin's `gf` = `git fetch` alias.)
frf() {
  local root
  root=$(jj root 2>/dev/null) \
    || root=$(/usr/bin/git rev-parse --show-toplevel 2>/dev/null) \
    || root=$PWD
  # Union: gitignore-respecting file list + force-included scratch* files.
  # node_modules / dist excluded explicitly as a belt-and-braces guard
  # (rg already skips them via .gitignore in normal repos).
  local excludes=(
    --glob '!.git' --glob '!.jj'
    --glob '!node_modules' --glob '!dist'
    --glob '!.next' --glob '!build' --glob '!target'
    --glob '!coverage' --glob '!.turbo' --glob '!.cache'
  )
  (cd "$root" && {
      rg --files --hidden "${excludes[@]}"
      rg --files --hidden --no-ignore --glob 'scratch*' --iglob '**/scratch*' "${excludes[@]}"
    } | sort -u \
    | fzf -m \
        --preview='bat --color=always --style=numbers "'"$root"'/{}"' \
        --bind 'enter:become(nvim '"$root"'/{+})')
}

if [[ $TERM_PROGRAM == iTerm.app ]]; then
  eval "$(zellij setup --generate-auto-start zsh)"
fi

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

function fe() {
  local query="${*:-}"
  fzf --ansi --disabled \
    --query "$query" \
    --bind "start:reload(rg --line-number --no-heading --smart-case --color=always -- {q} || true)" \
    --bind "change:reload(rg --line-number --no-heading --smart-case --color=always -- {q} || true)" \
    --delimiter : \
    --preview 'bat --style=full --color=always --highlight-line {2} {1}' \
    --preview-window '~4,+{2}+4/3' \
    --bind "ctrl-y:execute-silent(echo -n {1} | pbcopy)+bell" \
    --bind "ctrl-o:execute-silent(echo -n {1} | sed 's|.*/src/||;s|\.[^.]*$||;s|/|.|g' | pbcopy)+bell" \
    --bind "enter:become($EDITOR {1} +{2})" \
    </dev/null
}

source /Users/scarab5q/.config/broot/launcher/bash/br

function zoxide_fzf() {
  local orig_buffer=$LBUFFER
  local selection
  selection=$(zoxide query --list | fzf --height 40% --reverse --border) || {
    LBUFFER=$orig_buffer
    zle redisplay
    return 0
  }

  if [[ -n "$selection" ]]; then
    LBUFFER+="$selection"
    zle redisplay
  fi
}

function aws-mfa() {
  local base_profile="default"
  local region="eu-west-2"
  local duration="43200"
  local serial=""
  local code out ak sk tok exp

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -b)
      base_profile="$2"
      shift 2
      ;;
    -r)
      region="$2"
      shift 2
      ;;
    -d)
      duration="$2"
      shift 2
      ;;
    -s)
      serial="$2"
      shift 2
      ;;
    -h | --help)
      echo "usage: aws-mfa [-b baseProfile] [-r region] [-d durationSeconds] [-s mfaSerialArn]" >&2
      return 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      return 2
      ;;
    esac
  done

  command -v aws >/dev/null || {
    echo "aws not found" >&2
    return 1
  }
  command -v python3 >/dev/null || {
    echo "python3 not found" >&2
    return 1
  }

  if [[ -z "$serial" ]]; then
    serial="$(aws iam list-mfa-devices --profile "$base_profile" --query 'MFADevices[0].SerialNumber' --output text 2>/dev/null)"
    [[ -n "$serial" && "$serial" != "None" ]] || {
      echo "No MFA device found; pass -s <mfa-serial-arn>" >&2
      return 1
    }
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

  # Write to [mfa] profile so other processes (e.g. MCP servers) can use AWS_PROFILE=mfa
  aws configure set aws_access_key_id "$ak" --profile mfa
  aws configure set aws_secret_access_key "$sk" --profile mfa
  aws configure set aws_session_token "$tok" --profile mfa
  aws configure set region "$region" --profile mfa

  echo "AWS MFA session active (expires: $exp)"
}

function aws-1pass() {
  local base_profile="default"
  local region="eu-west-2"
  local duration="43200"
  local serial="arn:aws:iam::144392380677:mfa/1password"
  local code out ak sk tok exp

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -b)
      base_profile="$2"
      shift 2
      ;;
    -r)
      region="$2"
      shift 2
      ;;
    -d)
      duration="$2"
      shift 2
      ;;
    -s)
      serial="$2"
      shift 2
      ;;
    -h | --help)
      echo "usage: aws-1pass [-b baseProfile] [-r region] [-d durationSeconds] [-s mfaSerialArn]" >&2
      return 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      return 2
      ;;
    esac
  done

  command -v aws >/dev/null || {
    echo "aws not found" >&2
    return 1
  }
  command -v op >/dev/null || {
    echo "op (1Password CLI) not found" >&2
    return 1
  }
  command -v python3 >/dev/null || {
    echo "python3 not found" >&2
    return 1
  }

  code="$(op item get 'AWS' --otp)" || {
    echo "Failed to get TOTP from 1Password (item: 'AWS')" >&2
    return 1
  }

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

  aws configure set aws_access_key_id "$ak" --profile mfa
  aws configure set aws_secret_access_key "$sk" --profile mfa
  aws configure set aws_session_token "$tok" --profile mfa
  aws configure set region "$region" --profile mfa

  echo "AWS MFA session active (expires: $exp)"
}

export SSH_AUTH_SOCK=/Users/scarab5q/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh


. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"

# pnpm
export PNPM_HOME="/Users/scarab5q/Library/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# jj wrapper. Two jobs:
#  1. `jj autoclear` dispatches to ~/scripts/jj-autoclear (jj 0.41 has no
#     external-subcommand support, so we intercept here).
#  2. Serialize every jj invocation with flock on a lockfile in the shared repo
#     store. Multiple agents in separate jj *workspaces* share one .jj/repo (op
#     log + commit store), so concurrent jj commands race and produce divergent
#     operations/changes. One exclusive lock per repo makes them take turns.
jj() {
  local root link store lock
  # --ignore-working-copy: pure read, no snapshot op, so this lookup can't race.
  root=$(command jj root --ignore-working-copy 2>/dev/null)
  if [ -n "$root" ]; then
    link="$root/.jj/repo"
    # Main workspace: .jj/repo is a dir. Secondary workspace: it's a file
    # pointing at the main repo. Either way all workspaces resolve to one lock.
    [ -d "$link" ] && store="$link" || store="$(cat "$link" 2>/dev/null)"
    [ -n "$store" ] && lock="$(dirname "$store")/.agent-jj.lock"
  fi

  local -a cmd
  if [ "${1:-}" = "autoclear" ]; then
    shift
    cmd=(command ~/scripts/jj-autoclear "$@")
  else
    cmd=(command jj "$@")
  fi

  # -w 30: a hung network op (push/fetch) can't block other panes forever.
  if [ -n "$lock" ]; then
    flock -x -w 30 "$lock" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
}

# herdr session picker. Offers an fzf list of named herdr sessions to attach to.
# Invoke manually (e.g. `herdr_session_picker` or the `hp` alias below) — it no
# longer runs on shell start. The HERDR_PANE_ID / SHLVL guards keep `exec herdr
# session attach` from re-entering the picker inside spawned panes.
herdr_session_picker() {
  [[ -o interactive ]]              || return   # interactive only
  [[ -z "$HERDR_PANE_ID" ]]         || return   # not already inside a herdr pane
  command -v herdr >/dev/null       || { print -u2 "herdr not installed"; return 1; }
  command -v fzf   >/dev/null       || { print -u2 "fzf not installed"; return 1; }

  local sessions choice name
  sessions=$(herdr session list --json 2>/dev/null | jq -r '
    .sessions[]
    | "\(.name)\t\(if .running then "running" else "stopped" end)\(if .default then " · default" else "" end)"')

  choice=$(
    {
      [[ -n "$sessions" ]] && print -r -- "$sessions"
      print -r -- $'➕ new session…'
      print -r -- $'✕ skip (plain shell)'
    } | fzf --prompt='herdr session ❯ ' --height=40% --reverse \
            --header='Attach a herdr session (esc = plain shell)' \
            --delimiter='\t' --with-nth=1,2
  )
  [[ -n "$choice" ]] || return                  # esc → plain shell

  case "$choice" in
    *'skip (plain shell)'*) return ;;
    *'new session'*)
      read -r "name?New session name: "
      [[ -n "$name" ]] || return ;;
    *) name="${choice%%$'\t'*}" ;;
  esac

  exec herdr session attach "$name"
}
alias hp='herdr_session_picker'
