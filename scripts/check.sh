#!/usr/bin/env bash
# Checks installed VS Code / Cursor extensions against the glassworm-v2
# malicious package list.
#
# Usage: ./check_malicious_extensions.sh

set -euo pipefail

# Embedded glassworm-v2 affected packages (namespace.name|version|published)
MALICIOUS_DATA='federicanc.dotenv-syntax-highlighting|1.0.3|2026-03-10
blockstoks.easily-gitignore-manage|0.10.2|2026-03-09
dopbop-studio.vscode-tailwindcss-extension-toolkit|0.14.29|2026-03-06
kwitch-studio.auto-run-command-extension|1.6.2|2026-03-06
aligntool.extension-align-professional-tool|1.4.6|2026-03-05
runnerpost.runner-your-code|0.13.2|2026-03-05
rubyideext.ruby-ide-extension|0.10.0-alpha.2|2026-03-05
aadarkcode.one-dark-material|3.20.1|2026-03-05
pyscopexte.pyscope-extension|1.1.403|2026-03-03
pubruncode.ccoderunner|9.4.8|2026-03-02
codwayexten.code-way-extension|0.19.5|2026-03-02
toowespace.worksets-extension|0.2.41|2026-03-02
treedotree.tree-do-todoextension|0.0.216|2026-03-02
shinypy.shiny-extension-for-vscode|1.3.3|2026-03-02
markvalid.vscode-mdvalidator-extension|0.61.2|2026-03-02
errlenscre.error-lens-finder-ex|3.28.1|2026-03-02
daeumer-web.es-linter-for-vs-code|3.0.21|2026-03-02
devmidu-studio.svg-better-extension|0.4.41|2026-02-26
redcapcollective.vscode-quarkus-elite-suite|1.21.2025112809|2026-02-26
tima-web-wang.shell-check-utils|0.38.61|2026-02-26
brategmaqendaalar-studio.pro-prettyxml-formatter|6.4.2|2026-02-11
mecreation-studio.pyrefly-pro-extension|0.48.1|2026-02-11
dark-code-studio.flutter-extension|3.122.1|2026-02-11
dep-labs-studio.dep-proffesinal-extension|0.7.22|2026-02-11
densy-little-studio.wonder-for-vscode-icons|0.10.1|2026-02-03
lavender-studio.theme-lavender-dreams|1.0.3|2026-02-03
cosmic-themes.sql-formatter|4.2.6|2026-02-03
oorzc.scss-to-css-compile|1.3.4|2026-01-30
oorzc.i18n-tools-plus|1.6.8|2026-01-30
oorzc.ssh-tools|0.5.1|2026-01-30
oorzc.mind-map|1.0.61|2026-01-30
angular-studio.ng-angular-extension|21.1.1|2026-01-22
vce-brendan-studio-eich.js-debuger-vscode|1.105.1|2026-01-22
tucyzirille-studio.angular-pro-tools-extension|7.0.1|2026-01-22
ko-zu-gun-studio.synchronization-settings-vscode|0.18.3|2026-01-22
studio-jjalaire-team.professional-quarto-extension|1.126.1|2026-01-22
dev-studio-sense.php-comp-tools-vscode|1.63.18156|2026-01-17
lyu-wen-studio-web-han.better-formatter-vscode|1.1.5|2026-01-16
awesome-codebase.codebase-dart-pro|3.124.20251132|2026-01-13
sol-studio.solidity-extension|0.0.188|2026-01-11
sun-shine-studio.shiny-extension-for-vscode|1.3.3|2026-01-11
pretty-studio-advisor.prettyxml-formatter|6.4.2|2026-01-10
studio-velte-distributor.pro-svelte-extension|109.12.1|2025-12-28
littensy-studio.magical-icons|0.10.1|2025-12-26
cudra-production.vsce-prettier-pro|11.0.2|2025-12-21
cudra-production.vsce-prettier-pro|11.0.1|2025-12-21'

malicious_list=$(mktemp)
trap 'rm -f "$malicious_list"' EXIT
echo "$MALICIOUS_DATA" >"$malicious_list"

entry_count=$(wc -l <"$malicious_list" | tr -d ' ')
echo "Checking against $entry_count known malicious extensions (glassworm-v2)"
echo ""

found_any=false

check_editor() {
  local editor_name="$1"
  local cmd="$2"

  if ! command -v "$cmd" &>/dev/null; then
    echo "[$editor_name] '$cmd' CLI not found — skipping"
    echo ""
    return
  fi

  echo "[$editor_name] Checking installed extensions..."
  local installed
  installed=$("$cmd" --list-extensions 2>/dev/null) || true

  local match_count=0
  while IFS= read -r ext; do
    [[ -z "$ext" ]] && continue
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    match=$(grep "^${ext_lower}|" "$malicious_list" 2>/dev/null || true)
    if [[ -n "$match" ]]; then
      ver=$(echo "$match" | head -1 | cut -d'|' -f2)
      pub=$(echo "$match" | head -1 | cut -d'|' -f3)
      echo "  *** MATCH: $ext  (malicious version: $ver, published: $pub)"
      match_count=$((match_count + 1))
      found_any=true
    fi
  done <<<"$installed"

  if [[ $match_count -eq 0 ]]; then
    echo "  No malicious extensions found."
  else
    echo ""
    echo "  WARNING: $match_count malicious extension(s) detected in $editor_name!"
    echo "  Uninstall them immediately:  $cmd --uninstall-extension <id>"
  fi
  echo ""
}

check_editor "VS Code" "code"
check_editor "Cursor" "cursor"

if $found_any; then
  echo "=== ACTION REQUIRED: Malicious extensions detected! ==="
  echo "1. Uninstall the flagged extensions immediately"
  echo "2. Review system for signs of compromise"
  echo "3. Rotate any credentials/tokens accessible from your editor"
  exit 1
else
  echo "All clear — no malicious extensions from the glassworm-v2 list are installed."
  exit 0
fi
