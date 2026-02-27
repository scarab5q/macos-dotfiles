# Nushell Configuration

$env.config.edit_mode = 'vi'
$env.config.keybindings = ($env.config.keybindings | append {
    name: clear_screen
    modifier: control
    keycode: char_y
    mode: [emacs vi_normal vi_insert]
    event: { send: ClearScreen }
})

# ============================================================
# ALIASES
# ============================================================

# Config editing
alias zshconfig = nvim ~/.zshrc
alias nuconfig = nvim ~/.config/nushell/config.nu
alias nvimconfig = nvim ~/.config/nvim
alias ohmyzsh = nvim ~/.oh-my-zsh

# Reload config
def renu [] { exec nu }

# Dotfiles management (bare git repo)
def --wrapped cfg [...args] { ^git $"--git-dir=($env.HOME)/.cfg" $"--work-tree=($env.HOME)" ...$args }
def --wrapped lazyconfig [...args] { lazygit $"--git-dir=($env.HOME)/.cfg" $"--work-tree=($env.HOME)" ...$args }
alias lc = lazyconfig

# Lazygit
alias lg = lazygit

# Git branch switcher with fzf
def branches [] {
    let branch = (git branch
        | lines
        | where { |line| not ($line | str starts-with "*") }
        | each { |line| $line | str trim }
        | str join "\n"
        | fzf --height=20% --reverse --info=inline
        | str trim)
    if ($branch | is-not-empty) {
        git checkout $branch
    }
}

# Direnv
alias dall = direnv allow
alias dedit = direnv edit

# Docker
alias rd = bash ~/repos/arrow/scripts/start-docker.sh
alias rdb = bash ~/repos/arrow/scripts/start-docker.sh --build
def dockerstopall [] {
    let containers = (docker ps -q | lines)
    if ($containers | is-not-empty) {
        docker stop ...$containers
        docker rm ...$containers
    }
}
alias lzd = lazydocker

# GitHub
alias ghd = gh dash

# Just
alias jed = just --edit

# Eza (ls replacement)
alias ls = eza

# Zellij
alias zr = zellij run --

# Emacs
def ecl [...args] { emacsclient -a "" -c ...$args }

# ============================================================
# CUSTOM FUNCTIONS
# ============================================================

# Dotfiles picker with fzf (cf command)
def cf [] {
    let fmt = $env.HOME + '/%(path)'
    let files = (git --git-dir=($env.HOME | path join ".cfg") --work-tree=$env.HOME ls-tree --full-tree -r --full-name HEAD --format $fmt
        | fzf -m --preview 'bat --color=always {}'
        | lines)
    if ($files | is-not-empty) {
        nvim ...$files
    }
}

# Yazi file manager with cwd tracking
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp | str trim)
    if ($cwd | is-not-empty) and $cwd != $env.PWD {
        cd $cwd
    }
    rm -f $tmp
}

# AWS MFA helper
def aws-mfa [
    --base-profile (-b): string = "default"  # AWS base profile
    --region (-r): string = "eu-west-2"      # AWS region
    --duration (-d): int = 43200             # Session duration in seconds
    --serial (-s): string = ""               # MFA serial ARN (auto-detected if not provided)
] {
    let mfa_serial = if ($serial | is-empty) {
        let detected = (aws iam list-mfa-devices --profile $base_profile --query 'MFADevices[0].SerialNumber' --output text | str trim)
        if ($detected | is-empty) or $detected == "None" {
            error make {msg: "No MFA device found; pass --serial <mfa-serial-arn>"}
        }
        $detected
    } else {
        $serial
    }

    let code = (input $"MFA code for ($mfa_serial): ")

    let result = (aws sts get-session-token
        --profile $base_profile
        --serial-number $mfa_serial
        --token-code $code
        --duration-seconds $duration
        | from json)

    $env.AWS_ACCESS_KEY_ID = $result.Credentials.AccessKeyId
    $env.AWS_SECRET_ACCESS_KEY = $result.Credentials.SecretAccessKey
    $env.AWS_SESSION_TOKEN = $result.Credentials.SessionToken
    $env.AWS_REGION = $region
    $env.AWS_DEFAULT_REGION = $region
    $env.AWS_MFA_SESSION_EXPIRATION = $result.Credentials.Expiration

    print $"AWS MFA session active \(expires: ($result.Credentials.Expiration)\)"
}

# ============================================================
# INTEGRATIONS
# ============================================================

# Starship prompt
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Zoxide (cd replacement)
source ~/.zoxide.nu

# Cargo/Rust
source ~/.cargo/env.nu

# Direnv hook (runs on directory change)
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []
$env.config.hooks.env_change.PWD ++= [{||
    if (which direnv | is-empty) { return }
    direnv export json | from json | default {} | load-env
    # Fix PATH if direnv modified it (becomes string, needs to be list)
    if ($env.PATH | describe) == "string" {
        $env.PATH = ($env.PATH | split row (char esep))
    }
}]

# Atuin shell history
source ~/.local/share/atuin/init.nu

# Broot file manager
source ~/.config/nushell/broot.nu

# ============================================================
# COMPLETIONS
# ============================================================

# Just completions
source ~/.config/nushell/just-completions.nu

# Git completions (from nu_scripts)
use ~/.config/nushell/nu_scripts/custom-completions/git/git-completions.nu *

# ============================================================
# PATH ADDITIONS (must be at end to survive direnv/atuin)
# ============================================================

# pnpm global installs
$env.PNPM_HOME = ($env.HOME | path join "Library/pnpm")
$env.PATH = ($env.PATH | prepend $env.PNPM_HOME)

# Worktree scripts
$env.PATH = ($env.PATH | prepend ($env.HOME | path join "masref/core/bin"))

# Atuin
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".atuin/bin"))

# ============================================================
# ZELLIJ AUTO-START (iTerm only)
# ============================================================

if ($env.TERM_PROGRAM? == "iTerm.app") and ($env.ZELLIJ? | is-empty) {
    zellij
    if ($env.ZELLIJ_AUTO_EXIT? == "true") { exit }
}
