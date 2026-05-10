# macOS payload
echo "Checking macOS payload..."
ls -la /Library/Caches/com.apple.act.mond 2>/dev/null

# Temp file
echo "Checking temp file..."
ls -la "${TMPDIR}6202033" 2>/dev/null

# /etc/hosts
echo "Checking /etc/hosts..."
grep -iE "sfrclak|142\.11\.206\.73" /etc/hosts

# Active connections to C2
echo "Checking active connections..."
lsof -i -n -P 2>/dev/null | grep -E "142\.11\.206\.73|8000"
netstat -an 2>/dev/null | grep "142.11.206.73"

# DNS resolution logs (last 24h)
echo "Checking DNS logs (can take ~10s)..."
log show --predicate 'process == "mDNSResponder"' --last 24h 2>/dev/null | grep -i "sfrclak"

# C2 references in temp/cache
echo "Checking temp/cache for C2 artifacts..."
grep -r "packages.npm.org/product0" /tmp ~/Library/Caches 2>/dev/null
grep -r "sfrclak" /tmp ~/Library/Caches 2>/dev/null

echo "Done. No output between labels = clean."