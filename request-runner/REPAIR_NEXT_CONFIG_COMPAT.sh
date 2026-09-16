#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT CONFIG COMPATIBILITY REPAIR"
echo "=============================================================="

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/config-$STAMP"
LOG=".completion-logs/build-config-repair-$STAMP.log"

mkdir -p "$BACKUP" .completion-logs

echo
echo "[1/7] Locating Next.js configuration"

CONFIG=""

for f in next.config.js next.config.mjs next.config.ts; do
    if [ -f "$f" ]; then
        CONFIG="$f"
        break
    fi
done

if [ -z "$CONFIG" ]; then
    echo "ERROR: No next.config.js/mjs/ts found"
    exit 1
fi

echo "✓ Found: $CONFIG"

cp "$CONFIG" "$BACKUP/$(basename "$CONFIG")"

echo
echo "[2/7] Inspecting webpack/turbopack configuration"

grep -nEi \
  'webpack|turbopack|experimental|output|distDir' \
  "$CONFIG" 2>/dev/null || true

echo
echo "[3/7] Adding explicit Turbopack compatibility"

node <<'NODE'
const fs = require("fs");

const candidates = [
  "next.config.js",
  "next.config.mjs",
  "next.config.ts"
];

const file = candidates.find(fs.existsSync);

if (!file) {
  console.error("No Next config found");
  process.exit(1);
}

let s = fs.readFileSync(file, "utf8");

if (/\bturbopack\s*:/m.test(s)) {
  console.log("Turbopack configuration already exists.");
  process.exit(0);
}

/*
 * Next.js 16 requires an explicit Turbopack configuration
 * when a custom webpack configuration is present.
 *
 * Add the property without removing the existing webpack hook.
 */

const marker = "const nextConfig = {";

if (s.includes(marker)) {
  s = s.replace(
    marker,
    marker + "\n  turbopack: {},"
  );

  fs.writeFileSync(file, s);
  console.log(`Added turbopack: {} to ${file}`);
  process.exit(0);
}

/*
 * Handle common module.exports = { ... } form.
 */
const exportMarker = "module.exports = {";

if (s.includes(exportMarker)) {
  s = s.replace(
    exportMarker,
    exportMarker + "\n  turbopack: {},"
  );

  fs.writeFileSync(file, s);
  console.log(`Added turbopack: {} to ${file}`);
  process.exit(0);
}

console.error(
  `Could not safely identify the config object in ${file}.`
);
process.exit(2);
NODE

STATUS=$?

if [ "$STATUS" -ne 0 ]; then
    echo
    echo "Automatic config insertion was not safe."
    echo "Backup preserved at: $BACKUP"
    exit "$STATUS"
fi

echo "✓ Turbopack compatibility added"

echo
echo "[4/7] Showing resulting configuration"

grep -nEi \
  'turbopack|webpack|nextConfig|module.exports' \
  "$CONFIG" | head -80

echo
echo "[5/7] Clearing stale Next output"

rm -rf .next

echo "✓ .next cleared"

echo
echo "[6/7] Running production build"

set +e
npm run build >"$LOG" 2>&1
BUILD_STATUS=$?
set -e

if [ "$BUILD_STATUS" -ne 0 ]; then
    echo
    echo "=============================================================="
    echo " BUILD FAILED"
    echo "=============================================================="

    grep -nEi \
      'error|failed|failure|exception|fatal|cannot find|module not found|typescript|TS[0-9]+|syntax|parse|webpack|turbopack|npm ERR|ELIFECYCLE|permission|memory|heap|out of memory|pages-manifest' \
      "$LOG" | tail -80 || true

    echo
    echo "Last 50 lines:"
    tail -50 "$LOG"

    echo
    echo "Backup: $BACKUP"
    echo "Log:    $LOG"

    exit "$BUILD_STATUS"
fi

echo
echo "[7/7] Production artifact verification"

FAIL=0

if [ -d ".next" ]; then
    echo "✓ .next"
else
    echo "✗ .next"
    FAIL=1
fi

if [ -d ".next/server" ]; then
    echo "✓ .next/server"
else
    echo "✗ .next/server"
    FAIL=1
fi

if [ -f ".next/BUILD_ID" ]; then
    echo "✓ .next/BUILD_ID"
else
    echo "⚠ .next/BUILD_ID not present"
fi

if [ -f ".next/server/pages-manifest.json" ]; then
    echo "✓ pages-manifest.json"
else
    echo "⚠ pages-manifest.json not present"
fi

if [ "$FAIL" -ne 0 ]; then
    echo
    echo "=============================================================="
    echo " REPAIR FAILED — ARTIFACT VERIFICATION"
    echo "=============================================================="
    echo "Backup: $BACKUP"
    echo "Log:    $LOG"
    exit 1
fi

echo
echo "=============================================================="
echo " COMPLETION ENGINE® — BUILD PASS"
echo "=============================================================="
echo "Next.js configuration is compatible with Next.js 16."
echo "Build log: $LOG"
echo "Backup:    $BACKUP"
echo "=============================================================="

exit 0
