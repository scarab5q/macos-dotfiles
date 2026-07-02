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
$env.FORMAT_ON_COMMIT = "0"

# GPG TTY (needed for pinentry on commits/signs). Guarded — `tty` exits 1 when
# stdin isn't a terminal (e.g. when nu runs via `nu -c` from a script), which
# would otherwise abort env.nu evaluation.
$env.GPG_TTY = (try { ^tty | str trim } catch { "" })

# Brew shellenv side-effects (PREFIX/CELLAR/REPOSITORY are set above)
$env.MANPATH = "/opt/homebrew/share/man:"
$env.INFOPATH = "/opt/homebrew/share/info:"

# Bun
$env.BUN_INSTALL = ($env.HOME | path join ".bun")

# NVM
$env.NVM_DIR = ($env.HOME | path join ".nvm")

# PATH setup
$env.GOPATH = ($env.HOME | path join "go")

$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend "/usr/local/bin"
    | prepend "/opt/homebrew/bin"
    | prepend "/opt/homebrew/sbin"
    | prepend ($env.HOME | path join ".local/bin")
    | prepend ($env.HOME | path join "scripts")
    | prepend ($env.BUN_INSTALL | path join "bin")
    | prepend ($env.GOPATH | path join "bin")
    | append "/Applications/WezTerm.app/Contents/MacOS"
    | uniq
)

$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
mkdir $nu.cache-dir
carapace _carapace nushell | save --force ($nu.cache-dir | path join "carapace.nu")

# SSH agent: point at Secretive's socket (Touch ID-backed keys in Secure Enclave).
# Matches zsh's `export SSH_AUTH_SOCK=...` — no separate ssh-agent process needed.
$env.SSH_AUTH_SOCK = ($env.HOME | path join "Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh")

# OrbStack: ships init scripts for bash/zsh/fish only — its setup is just
# adding ~/.orbstack/bin to PATH (plus zsh completions we don't need here).
$env.PATH = ($env.PATH | append ($env.HOME | path join ".orbstack/bin") | uniq)

# Load ~/.secrets (zsh `export FOO=bar` style). zsh sources it directly; nu
# can't, so we parse each `export NAME=VALUE` line, strip surrounding quotes,
# and merge into the environment. Missing file = no-op (parity with zsh's
# `[ -f ~/.secrets ] && source ~/.secrets`).
let secrets_file = ($env.HOME | path join ".secrets")
if ($secrets_file | path exists) {
    open --raw $secrets_file
    | lines
    | parse "export {name}={value}"
    | reduce -f {} { |it, acc| $acc | upsert $it.name ($it.value | str trim --char '"') }
    | load-env
}

# Zoxide init (must be at end of env.nu)
zoxide init nushell | save -f ~/.zoxide.nu
