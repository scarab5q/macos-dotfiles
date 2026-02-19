# Nushell Configuration
# Mirrors .zshrc settings

# ============================================================
# ALIASES
# ============================================================

# Config editing
alias zshconfig = nvim ~/.zshrc
alias nuconfig = nvim ~/.config/nu/config.nu
alias nvimconfig = nvim ~/.config/nvim
alias ohmyzsh = nvim ~/.oh-my-zsh

# Reload config
def renu [] {
    source ~/.config/nu/env.nu
    source ~/.config/nu/config.nu
}

# Dotfiles management (bare git repo)
alias config = git --git-dir=($env.HOME | path join ".cfg") --work-tree=$env.HOME
alias lazyconfig = lazygit --git-dir=($env.HOME | path join ".cfg") --work-tree=$env.HOME
alias lc = lazygit --git-dir=($env.HOME | path join ".cfg") --work-tree=$env.HOME

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

# Use eza for ls
alias ls = eza

# ============================================================
# CUSTOM FUNCTIONS
# ============================================================

# Dotfiles picker with fzf (cf command)
def cf [] {
    let files = (git --git-dir=($env.HOME | path join ".cfg") --work-tree=$env.HOME ls-tree --full-tree -r --full-name HEAD
        | lines
        | each { |line|
            $line | split column "\t" | get column2.0 | $env.HOME | path join $in
        }
        | str join "\n"
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
    # Get MFA serial if not provided
    let mfa_serial = if ($serial | is-empty) {
        let detected = (aws iam list-mfa-devices --profile $base_profile --query 'MFADevices[0].SerialNumber' --output text | str trim)
        if ($detected | is-empty) or $detected == "None" {
            error make {msg: "No MFA device found; pass --serial <mfa-serial-arn>"}
        }
        $detected
    } else {
        $serial
    }

    # Prompt for MFA code
    let code = (input $"MFA code for ($mfa_serial): ")

    # Get session token
    let result = (aws sts get-session-token
        --profile $base_profile
        --serial-number $mfa_serial
        --token-code $code
        --duration-seconds $duration
        | from json)

    # Export credentials
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

# Zoxide (cd replacement) - use z/zi commands
source ~/.config/nu/zoxide.nu

# Direnv hook (requires nushell 0.104+)
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []
$env.config.hooks.env_change.PWD ++= [{||
    if (which direnv | is-empty) { return }
    direnv export json | from json | default {} | load-env
    # Fix PATH if direnv modified it (becomes string, needs to be list)
    if ($env.PATH | describe) == "string" {
        $env.PATH = ($env.PATH | split row (char esep))
    }
}]

# Starship prompt (optional) - run: starship init nu | save -f ~/.config/nu/starship.nu
# source ~/.config/nu/starship.nu

# Broot - check if nushell config exists
# source ~/.config/broot/launcher/nushell/br

# ============================================================
# COMPLETIONS
# ============================================================

# Just completions
source ~/.config/nu/just-completions.nu
