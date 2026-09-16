#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/next16-webpack-isolation-$STAMP"
LOG=".completion-logs/next16-webpack-isolation-$STAMP.log"

mkdir -p "$BACKUP" .completion-logs

cp next.config.js "$BACKUP/next.config.js"
cp package.json "$BACKUP/package.json"
[ -f package-lock.json ] && cp package-lock.json "$BACKUP/package-lock.json"

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT 16 WEBPACK ISOLATION"
echo "=============================================================="
echo
echo "Backup: $BACKUP"
echo

echo "[1/5] Creating temporary baseline configuration"

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

echo "✓ Custom Webpack hook isolated"
echo

echo "[2/5] Clearing generated build state"

rm -rf .next

echo "✓ .next cleared"
echo

echo "[3/5] Running ONE controlled production build"

set +e

npm run build 2>&1 | tee "$LOG"

BUILD_STATUS=${PIPESTATUS[0]}

set -e

echo
echo "[4/5] Inspecting result"

if [ "$BUILD_STATUS" -eq 0 ]; then
    echo "✓ BUILD PASSED WITHOUT CUSTOM WEBPACK HOOK"

    if [ -f ".next/server/pages-manifest.json" ]; then
        echo "✓ pages-manifest.json PRESENT"
    else
        echo "! Build passed but pages-manifest.json is absent"
    fi

    if [ -f ".next/server/app-paths-manifest.json" ]; then
        echo "✓ app-paths-manifest.json PRESENT"
    else
        echo "! app-paths-manifest.json absent"
    fi

    RESULT="PASS"
else
    echo "✗ BUILD STILL FAILS WITHOUT CUSTOM WEBPACK HOOK"
    echo
    echo "Relevant failure:"
    grep -nEi \
        'Build error|Error:|ENOENT|manifest|Collecting page data|worker|route' \
        "$LOG" \
        | tail -40 || true

    RESULT="FAIL"
fi

echo
echo "[5/5] Restoring original configuration"

cp "$BACKUP/next.config.js" next.config.js

echo "✓ Original next.config.js restored"

echo
echo "=============================================================="
echo " ISOLATION RESULT: $RESULT"
echo "=============================================================="
echo "Log:    $LOG"
echo "Backup: $BACKUP"
echo "=============================================================="

exit "$BUILD_STATUS"
