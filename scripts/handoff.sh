#!/usr/bin/env bash
# handoff.sh: fire-and-forget a delegated `claude` agent into a NEW cmux tab
# (surface) inside the CURRENT pane, seeded with a handoff prompt.
#
# This is the lightweight cousin of the "new jj workspace + workspace tab" flow:
# when you just want to kick off a quick same-pane sub-task and forget about it,
# this spawns the agent right where you are, no monitoring required.
#
# Usage:
#   handoff.sh <prompt-file | inline prompt text> [cwd]
#
#   <prompt>  If it's an existing file, it's used as the prompt file verbatim.
#             Otherwise the argument is treated as inline prompt text and
#             written to a temp file.
#   [cwd]     Working directory for the new tab. Defaults to $PWD.
#
# Example:
#   handoff.sh "Investigate the flaky test in foo_spec and report back." ~/repos/app
#   handoff.sh ./PROMPT.md
#
# Prints the created surface ref (e.g. surface:42) so the caller knows what was
# spawned (close it later with: cmux close-surface --surface surface:42).

set -euo pipefail

usage() {
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

case "${1:-}" in
  -h | --help | "") usage 0 ;;
esac

prompt_arg="$1"
cwd="${2:-$PWD}"

# --- Resolve the prompt file (absolute path so `cat` works from any cwd) ----
if [[ -f "$prompt_arg" ]]; then
  prompt_file="$(cd "$(dirname "$prompt_arg")" && pwd)/$(basename "$prompt_arg")"
else
  # BSD/macOS mktemp requires the X's to be a trailing run (no suffix).
  prompt_file="$(mktemp "${TMPDIR:-/tmp}/handoff.XXXXXX")"
  printf '%s\n' "$prompt_arg" > "$prompt_file"
fi

# --- Find the pane we were invoked from -------------------------------------
pane="$(cmux identify --json | grep -oE '"pane_ref" : "pane:[0-9]+"' | head -1 | grep -oE 'pane:[0-9]+')"
if [[ -z "${pane:-}" ]]; then
  echo "handoff: could not resolve current cmux pane (is this running inside cmux?)" >&2
  exit 1
fi

# --- Create a focused terminal surface in that pane -------------------------
surface="$(
  cmux new-surface --type terminal --pane "$pane" --working-directory "$cwd" --focus true |
    grep -oE 'surface:[0-9]+' | head -1
)"
if [[ -z "${surface:-}" ]]; then
  echo "handoff: failed to create surface in $pane" >&2
  exit 1
fi

# --- Seed the agent. `claude <text>` starts an interactive session with that
# prompt; command substitution output is not re-scanned, so backticks in the
# prompt are safe. Trailing \n submits the line. -----------------------------
cmux send --surface "$surface" "claude \"\$(cat $prompt_file)\"\n" >/dev/null

echo "$surface"
