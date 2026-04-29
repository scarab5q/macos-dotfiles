# XDG Base Directory (used by nushell, and many other tools)
export XDG_CONFIG_HOME="$HOME/.config"

eval "$(/opt/homebrew/bin/brew shellenv)"
export EDITOR="nvim"
# Source secrets from gitignored file
[ -f ~/.secrets ] && source ~/.secrets
export PATH="$HOME/scripts:$PATH"
export PATH="/Users/scarab5q/.local/bin:$PATH"
export HISTORY_IGNORE="(doppler secrets set*)"
export REPOS=/Users/scarab5q/repos
export ARROW=$REPOS/arrow
export BACKEND=$ARROW/apps/backend
export ARQ=$REPOS/arq
export PUSH_FORMAT_CHECK=0
export RIPGREP_CONFIG_PATH=/Users/scarab5q/.ripgreprc
# 1Password secrets are cached in ~/.secrets
# Run `refresh-secrets` to re-fetch from 1Password (requires Touch ID once)
# export OPENAI_API_KEY=$(op item get 5vjtbazh33oddjbodlkjbhifvi --fields password --reveal)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
