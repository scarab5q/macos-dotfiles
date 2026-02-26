# Nushell Environment Configuration
# Mirrors .zprofile settings

# Homebrew setup
$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"

# Editor
$env.EDITOR = "nvim"

# Ripgrep config
$env.RIPGREP_CONFIG_PATH = ($env.HOME | path join ".ripgreprc")

# Project paths
$env.REPOS = ($env.HOME | path join "repos")
$env.ARROW = ($env.REPOS | path join "arrow")
$env.BACKEND = ($env.ARROW | path join "apps/backend")
$env.ARQ = ($env.REPOS | path join "arq")

# Misc settings
$env.PUSH_FORMAT_CHECK = "0"
$env.HISTORY_IGNORE = "(doppler secrets set*)"

# Bun
$env.BUN_INSTALL = ($env.HOME | path join ".bun")

# NVM
$env.NVM_DIR = ($env.HOME | path join ".nvm")

# PATH setup
$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend "/opt/homebrew/bin"
    | prepend "/opt/homebrew/sbin"
    | prepend ($env.HOME | path join ".local/bin")
    | prepend ($env.HOME | path join "scripts")
    | prepend ($env.BUN_INSTALL | path join "bin")
    | uniq
)

# SSH agent setup - reuses existing agent or starts new one
# (avoids spawning multiple agents per terminal)
do --env {
    let ssh_agent_file = ($nu.temp-dir | path join $"ssh-agent-(whoami).nuon")

    if ($ssh_agent_file | path exists) {
        let ssh_agent_env = (open $ssh_agent_file)
        let agent_alive = if ($nu.os-info.name == "macos") {
            ($ssh_agent_env.SSH_AUTH_SOCK | path exists)
        } else {
            ($"/proc/($ssh_agent_env.SSH_AGENT_PID)" | path exists)
        }
        if $agent_alive {
            load-env $ssh_agent_env
            return
        } else {
            rm $ssh_agent_file
        }
    }

    let ssh_agent_env = (^ssh-agent -c
        | lines
        | first 2
        | parse "setenv {name} {value};"
        | transpose --header-row
        | into record)
    load-env $ssh_agent_env
    $ssh_agent_env | save --force $ssh_agent_file
}

# Zoxide init (must be at end of env.nu)
zoxide init nushell | save -f ~/.zoxide.nu
