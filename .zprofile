eval "$(/opt/homebrew/bin/brew shellenv)"
export EDITOR="nvim"
# Source secrets from gitignored file
[ -f ~/.secrets ] && source ~/.secrets
export PATH=~/scripts:$PATH
export PATH="/Users/scarab5q/.local/bin:$PATH"
export HISTORY_IGNORE="(doppler secrets set*)"
export REPOS=/Users/scarab5q/repos
export ARROW=$REPOS/arrow
export BACKEND=$ARROW/apps/backend
export ARQ=$REPOS/arq
export PUSH_FORMAT_CHECK=1
export RIPGREP_CONFIG_PATH=/Users/scarab5q/.ripgreprc



