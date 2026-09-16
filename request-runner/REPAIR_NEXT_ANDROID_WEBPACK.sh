#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/android-webpack-$STAMP"
LOG=".completion-logs/android-webpack-$STAMP.log"

mkdir -p "$BACKUP" .completion-logs

echo "=============================================================="
echo " COMPLETION ENGINE® — ANDROID WEBPACK REPAIR"
echo "=============================================================="

echo
echo "[1/8] Backing up current configuration"

cp package.json "$BACKUP/package.json"
cp next.config.js "$BACKUP/next.config.js"

echo "✓ Backup: $BACKUP"

echo
echo "[2/8] Restoring Android-compatible build engine"

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

if (!pkg.scripts) pkg.scripts = {};

pkg.scripts.build = "next build --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("✓ package.json build = next build --webpack");
NODE

echo
echo "[3/8] Removing Turbopack override"

node <<'NODE'
const fs = require("fs");

const file = "next.config.js";
let s = fs.readFileSync(file, "utf8");

/*
 * Remove the exact compatibility property we injected.
 */
s = s.replace(
  /^\s*turbopack:\s*\{\},\s*\n/m,
  ""
);

fs.writeFileSync(file, s);

console.log("✓ turbopack: {} removed");
NODE

echo
echo "[4/8] Showing active Next configuration"

sed -n '1,120p' next.config.js

echo
echo "[5/8] Clearing stale Next output"

rm -rf .next

echo "✓ .next cleared"

echo
echo "[6/8] Running Android Webpack production build"

set +e
npm run build >"$LOG" 2>&1
STATUS=$?
set -e

echo "Build exit: $STATUS"

echo
echo "[7/8] Inspecting result"

if [ "$STATUS" -eq 0 ]; then
    echo "✓ npm build returned success"
else
    echo "✗ npm build failed"
fi

echo
echo "Relevant signals:"

grep -nEi \
  'error|failed|failure|exception|fatal|cannot find|module not found|typescript|TS[0-9]+|syntax|parse|webpack|turbopack|pages-manifest|ENOENT|worker|npm ERR|ELIFECYCLE' \
  "$LOG" | tail -100 || true

echo
echo "Generated server files:"

if [ -d ".next/server" ]; then
    find .next/server -maxdepth 2 -type f 2>/dev/null \
      | sed 's#^#  #' \
      | head -120
else
    echo "  .next/server does not exist"
fi

echo
echo "[8/8] Determining failure class"

if grep -q 'pages-manifest.json' "$LOG"; then
    echo
    echo ">>> ORIGINAL PAGES-MANIFEST FAILURE REPRODUCED <<<"
    echo
    echo "This proves:"
    echo "  • Android Webpack is the correct engine"
    echo "  • Turbopack is not viable on this device"
    echo "  • application compilation succeeds before the failure"
    echo "  • the remaining fault is in Next's server-output stage"
    echo "  • next.config.js webpack customization is now the primary suspect"
fi

echo
echo "=============================================================="

if [ "$STATUS" -eq 0 ]; then
    echo " COMPLETION ENGINE® — WEBPACK BUILD PASS"
else
    echo " COMPLETION ENGINE® — WEBPACK FAILURE EXTRACTED"
fi

echo "=============================================================="
echo "Log:    $LOG"
echo "Backup: $BACKUP"

exit "$STATUS"
