#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT BUILD AUTO-REPAIR"
echo "=============================================================="

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/next-build-$STAMP"
mkdir -p "$BACKUP" .completion-logs

cp -f package.json "$BACKUP/package.json" 2>/dev/null || true
cp -f next.config.js "$BACKUP/next.config.js" 2>/dev/null || true
cp -f next.config.mjs "$BACKUP/next.config.mjs" 2>/dev/null || true
cp -f next.config.ts "$BACKUP/next.config.ts" 2>/dev/null || true

echo
echo "[1/6] Inspecting build command"

BUILD_SCRIPT="$(node -e '
const p=require("./package.json");
process.stdout.write((p.scripts&&p.scripts.build)||"");
')"

echo "Build: $BUILD_SCRIPT"

if printf '%s\n' "$BUILD_SCRIPT" | grep -q -- '--webpack'; then
    echo "Removing forced --webpack..."

    node <<'NODE'
const fs = require("fs");
const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

if (pkg.scripts?.build) {
    pkg.scripts.build = pkg.scripts.build
        .replace(/\s+--webpack\b/g, "")
        .replace(/\s{2,}/g, " ")
        .trim();
}

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
NODE

    echo "✓ Build command repaired"
else
    echo "✓ Build command already uses normal Next.js pipeline"
fi

echo
echo "[2/6] Clearing stale build state"
rm -rf .next
echo "✓ .next removed"

echo
echo "[3/6] Running production build"

LOG=".completion-logs/build-repair-$STAMP.log"

set +e
npm run build >"$LOG" 2>&1
STATUS=$?
set -e

echo "Build exit: $STATUS"

echo
echo "[4/6] Checking output"

if [ "$STATUS" -eq 0 ] && [ -d ".next" ] && [ -d ".next/server" ]; then
    echo "✓ Production build generated"
    echo "✓ .next/server exists"
else
    echo "✗ Production build did not complete"

    echo
    echo "Failure signals:"
    grep -nEi \
      'error|failed|failure|exception|fatal|cannot find|module not found|typescript|TS[0-9]+|syntax|parse|webpack|npm ERR|ELIFECYCLE|permission|memory|heap|out of memory|pages-manifest' \
      "$LOG" | tail -60 || true

    echo
    echo "Last 40 lines:"
    tail -40 "$LOG"

    echo
    echo "Backup: $BACKUP"
    echo "Log:    $LOG"

    exit 1
fi

echo
echo "[5/6] Verifying build identity"

[ -f ".next/BUILD_ID" ] \
    && echo "✓ BUILD_ID" \
    || echo "WARNING: BUILD_ID missing"

[ -d ".next/server" ] \
    && echo "✓ server output" \
    || exit 1

echo
echo "[6/6] Repair complete"

echo "=============================================================="
echo " COMPLETION ENGINE® — REPAIR PASS"
echo "=============================================================="
echo "Build log: $LOG"
echo "Backup:    $BACKUP"

exit 0
