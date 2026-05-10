#!/usr/bin/env bash
# macOS Compromise Detection & Cleanup Script
# Detects artifacts from a multi-stage Node.js RAT/stealer
# Run with: bash detect.sh [--clean]
#
# --clean: Remove detected artifacts (default: detect only)

set -euo pipefail

CLEAN=false
FOUND=0

if [[ "${1:-}" == "--clean" ]]; then
  CLEAN=true
  echo "=== CLEANUP MODE — artifacts will be removed ==="
  echo ""
fi

red() { printf "\033[1;31m%s\033[0m\n" "$1"; }
green() { printf "\033[1;32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$1"; }

check() {
  local label="$1"
  local path="$2"

  if [ -e "$path" ]; then
    red "[FOUND] $label: $path"
    FOUND=$((FOUND + 1))
    if $CLEAN; then
      rm -rf "$path"
      yellow "  -> Removed: $path"
    fi
  else
    green "[CLEAN] $label"
  fi
}

echo "====================================="
echo " macOS RAT/Stealer IOC Detection"
echo "====================================="
echo ""

# 1. LaunchAgent persistence
echo "--- Persistence ---"
check "LaunchAgent plist" "$HOME/Library/LaunchAgents/com.user.nodestart.plist"

# If the LaunchAgent is loaded, unload it before removing
if $CLEAN && launchctl list 2>/dev/null | grep -q "com.user.nodestart"; then
  launchctl unload "$HOME/Library/LaunchAgents/com.user.nodestart.plist" 2>/dev/null || true
  yellow "  -> Unloaded LaunchAgent"
fi

echo ""

# 2. Hidden Node.js install
echo "--- Hidden Node.js Runtime ---"
check "Hidden Node.js directory" "$HOME/.config/system/.data/.nodejs"

echo ""

# 3. RAT state file
echo "--- RAT State ---"
check "RAT init file (~/init.json)" "$HOME/init.json"

echo ""

# 4. Error logs (eval/message handler)
echo "--- Error Logs ---"
error_files=()
while IFS= read -r -d '' f; do
  error_files+=("$f")
done < <(find "$HOME" -maxdepth 3 -name "error*XkrnQlLAX*" -print0 2>/dev/null || true)

if [ ${#error_files[@]} -gt 0 ]; then
  for f in "${error_files[@]}"; do
    red "[FOUND] Error log: $f"
    FOUND=$((FOUND + 1))
    if $CLEAN; then
      rm -f "$f"
      yellow "  -> Removed: $f"
    fi
  done
else
  green "[CLEAN] No error*XkrnQlLAX* logs found"
fi

echo ""

# 5. Keychain entry (phished password)
echo "--- Keychain ---"
if security find-generic-password -s "pass_users_for_script" 2>/dev/null | grep -q "pass_users_for_script"; then
  red "[FOUND] Keychain entry: pass_users_for_script"
  FOUND=$((FOUND + 1))
  if $CLEAN; then
    security delete-generic-password -s "pass_users_for_script" 2>/dev/null || true
    yellow "  -> Deleted keychain entry"
    red "  !! WARNING: Your macOS password was likely stolen. CHANGE IT IMMEDIATELY."
  fi
else
  green "[CLEAN] No phished-password keychain entry"
fi

echo ""

# 6. SOCKS proxy / WebRTC module
echo "--- SOCKS Proxy Module ---"
check "WebRTC proxy module" "$HOME/.config/system/.data/.nodejs/webrtc/index.js"

echo ""

# 7. Stolen data staging
echo "--- Data Exfil Staging ---"
check "FileGrabber staging dir (/tmp/ijewf)" "/tmp/ijewf"
check "Exfil archive (/tmp/out.zip)" "/tmp/out.zip"

echo ""

# 8. Network IOCs — check for active connections
echo "--- Active Network Connections ---"
C2_IPS=("217.69.11.99" "208.76.223.59" "208.85.20.124")

for ip in "${C2_IPS[@]}"; do
  if lsof -i -nP 2>/dev/null | grep -q "$ip"; then
    red "[FOUND] Active connection to C2: $ip"
    FOUND=$((FOUND + 1))
    if $CLEAN; then
      # Kill processes connected to C2
      pids=$(lsof -i -nP 2>/dev/null | grep "$ip" | awk '{print $2}' | sort -u)
      for pid in $pids; do
        kill -9 "$pid" 2>/dev/null || true
        yellow "  -> Killed PID $pid (connected to $ip)"
      done
    fi
  else
    green "[CLEAN] No active connection to $ip"
  fi
done

echo ""

# 9. Broader .config/system cleanup check
echo "--- Suspicious .config/system tree ---"
check "Suspicious .config/system/.data" "$HOME/.config/system/.data"

echo ""
echo "====================================="
if [ $FOUND -eq 0 ]; then
  green "No indicators of compromise detected."
else
  red "$FOUND indicator(s) found."
  if ! $CLEAN; then
    echo ""
    yellow "Run with --clean to remove detected artifacts:"
    yellow "  bash $0 --clean"
  else
    echo ""
    red "POST-CLEANUP ACTIONS REQUIRED:"
    red "  1. Change your macOS login password immediately"
    red "  2. Rotate all credentials stored in browsers/keychains"
    red "  3. Revoke active sessions (GitHub, AWS, cloud providers)"
    red "  4. Check for unauthorized SSH keys in ~/.ssh/authorized_keys"
    red "  5. Review recent git commits for supply-chain tampering"
    red "  6. Block these IPs at your firewall:"
    red "     - 217.69.11.99  (Socket.IO C2)"
    red "     - 208.76.223.59 (AppleScript exfil)"
    red "     - 208.85.20.124 (Node.js exfil)"
  fi
fi

exit $FOUND
