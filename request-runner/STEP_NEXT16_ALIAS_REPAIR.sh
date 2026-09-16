#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/alias-repair-$STAMP"
LOG=".completion-logs/alias-repair-$STAMP.log"

mkdir -p "$BACKUP" .completion-logs

cp next.config.js "$BACKUP/next.config.js"

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT 16 ALIAS REPAIR"
echo "=============================================================="
echo
echo "Backup: $BACKUP"
echo

echo "[1/6] Inventorying alias usage"

grep -RInE \
    --exclude-dir=node_modules \
    --exclude-dir=.next \
    --exclude-dir=.git \
    --exclude='STEP_*.sh' \
    '(@framework/|@app/|@\.)' \
    . 2>/dev/null \
    | head -100 > "$BACKUP/alias-usage.txt" || true

if [ -s "$BACKUP/alias-usage.txt" ]; then
    echo "Alias references found:"
    cat "$BACKUP/alias-usage.txt"
else
    echo "No source alias references found."
fi

echo
echo "[2/6] Inspecting framework directory"

if [ -d framework ]; then
    echo "✓ framework/"
    find framework -maxdepth 2 -type f | sort | head -80
else
    echo "! framework/ does not exist"
fi

echo
echo "[3/6] Inspecting jsconfig/tsconfig"

if [ -f jsconfig.json ]; then
    echo "--- jsconfig.json ---"
    cat jsconfig.json
fi

if [ -f tsconfig.json ]; then
    echo "--- tsconfig.json ---"
    cat tsconfig.json
fi

echo
echo "[4/6] Installing stable alias configuration"

cat > next.config.js <<'CONFIGEOF'
/** @type {import('next').NextConfig} */

const nextConfig = {
    allowedDevOrigins: [
        "127.0.0.1",
        "localhost",
        "192.168.1.188"
    ]
};

module.exports = nextConfig;
CONFIGEOF

echo "✓ Removed custom Webpack mutation"
echo "✓ Preserved allowedDevOrigins"

echo
echo "[5/6] Clearing build state"

rm -rf .next

echo "✓ .next cleared"

echo
echo "[6/6] Production verification"

set +e

npm run build 2>&1 | tee "$LOG"

STATUS=${PIPESTATUS[0]}

set -e

echo
echo "=============================================================="

if [ "$STATUS" -eq 0 ]; then
    echo " REPAIR RESULT: PASS"
    echo "=============================================================="

    echo "✓ Production build passed"
    echo "✓ Custom Webpack mutation eliminated"

    [ -f ".next/server/pages-manifest.json" ] \
        && echo "✓ pages-manifest.json"

    [ -f ".next/server/app-paths-manifest.json" ] \
        && echo "✓ app-paths-manifest.json"

    echo
    echo "The Webpack-hook root cause is resolved."
    echo
    echo "Log: $LOG"
    echo "Backup: $BACKUP"

    exit 0
else
    echo " REPAIR RESULT: FAIL"
    echo "=============================================================="

    echo
    echo "Relevant failure:"
    grep -nEi \
        'Build error|Error:|ENOENT|manifest|Collecting page data|worker|route' \
        "$LOG" \
        | tail -50 || true

    echo
    echo "Restoring previous configuration..."

    cp "$BACKUP/next.config.js" next.config.js

    echo "✓ Previous configuration restored"
    echo "Log: $LOG"
    echo "Backup: $BACKUP"

    exit "$STATUS"
fi
