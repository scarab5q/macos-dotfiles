#!/bin/sh
# Wrapper to make `oxlint --fix` work as a jj fix tool.
# jj fix passes file contents on stdin and expects fixed contents on stdout.
# oxlint --fix only operates on files, and panics if the file is outside the
# repo root (gitignore handling), so we round-trip via a temp file placed
# *next to* the original.
#
# Usage in jj config: command = ["sh", "/path/to/oxlint-fix.sh", "$path"]

set -e

# Silence npm's "Unknown project config" warnings about pnpm-specific .npmrc keys.
export NPM_CONFIG_LOGLEVEL=error

path="$1"
dir=$(dirname "$path")
base=$(basename "$path")
ext="${base##*.}"

# Place the temp file next to the original so oxlint sees it as inside the repo.
# BSD mktemp (macOS) requires the X's at the end of the template, so we add the
# extension after.
tmp_base=$(mktemp "$dir/.jj-oxlint.XXXXXX")
tmp="$tmp_base.$ext"
mv "$tmp_base" "$tmp"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp"

# oxlint exits non-zero on remaining lint errors after fixing — that's expected.
npx --no-install oxlint --fix --quiet "$tmp" >/dev/null 2>&1 || true

cat "$tmp"
