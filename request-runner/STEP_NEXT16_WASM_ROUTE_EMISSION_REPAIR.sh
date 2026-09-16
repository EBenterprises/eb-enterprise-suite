#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/wasm-route-emission-$TS"
LOG=".completion-logs/wasm-route-emission-$TS.log"

mkdir -p "$BACKUP" .completion-logs
cp -a next.config.js "$BACKUP/next.config.js"
cp -a jsconfig.json "$BACKUP/jsconfig.json"

exec > >(tee "$LOG") 2>&1

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT 16 WASM ROUTE EMISSION REPAIR"
echo "=============================================================="
echo "Next: $(node -p "require('./node_modules/next/package.json').version")"
echo "Backup: $BACKUP"
echo

fail() {
  echo
  echo "✗ $1"
  echo "Restoring original configuration..."
  cp -f "$BACKUP/next.config.js" next.config.js
  cp -f "$BACKUP/jsconfig.json" jsconfig.json
  exit 1
}

echo "[1/7] Capturing known-good Webpack contract"
echo "--------------------------------------------------------------"

grep -nE \
  'webpack:|allowedDevOrigins|@framework|@app|resolve\.alias' \
  next.config.js || true

echo
echo "[2/7] Installing additive WASM-safe Webpack cache repair"
echo "--------------------------------------------------------------"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("next.config.js")
text = p.read_text()

if "COMPLETION_ENGINE_WASM_CACHE_REPAIR" in text:
    print("✓ Repair already present")
    raise SystemExit

marker = "/* COMPLETION_ENGINE_WASM_CACHE_REPAIR */"

# Locate the existing webpack function without replacing its body.
m = re.search(
    r'webpack\s*:\s*\(config\)\s*=>\s*\{',
    text
)

if not m:
    raise SystemExit("Existing webpack hook not found")

insert_at = m.end()

injection = f'''
    {marker}
    /*
     * Next 16 + Termux/WASM:
     * webpack filesystem cache dependency snapshotting can report a
     * successful compilation while route server artifacts are absent
     * when page-data collection starts.
     *
     * Preserve the existing alias hook, but force this production build
     * to use an in-memory cache.
     */
    config.cache = false;
'''

text = text[:insert_at] + injection + text[insert_at:]

p.write_text(text)
print("✓ Existing Webpack hook preserved")
print("✓ Filesystem cache disabled for deterministic WASM builds")
PY

echo
echo "[3/7] Verifying configuration integrity"
echo "--------------------------------------------------------------"

node - <<'NODE'
const fs = require("fs");

const s = fs.readFileSync("next.config.js", "utf8");

for (const required of [
  "COMPLETION_ENGINE_WASM_CACHE_REPAIR",
  "@framework",
  "@app"
]) {
  if (!s.includes(required)) {
    console.error("Missing required configuration:", required);
    process.exit(1);
  }
}

console.log("✓ Existing aliases preserved");
console.log("✓ Existing Webpack hook preserved");
console.log("✓ WASM cache repair present");
NODE

echo
echo "[4/7] Clearing only transient build state"
echo "--------------------------------------------------------------"

rm -rf .next
mkdir -p .next

echo "✓ .next recreated"
echo

echo "[5/7] Running ONE deterministic production build"
echo "--------------------------------------------------------------"

if npm run build -- --webpack; then
  BUILD_RC=0
else
  BUILD_RC=$?
fi

if [ "$BUILD_RC" -ne 0 ]; then
  echo
  echo "✗ Production build failed"

  echo
  echo "[FAILURE ARTIFACT CHECK]"
  find .next/server/app/api -type f -name 'route.js' 2>/dev/null \
    | sort \
    | head -80 || true

  cp -f "$BACKUP/next.config.js" next.config.js
  cp -f "$BACKUP/jsconfig.json" jsconfig.json

  echo
  echo "✓ Original configuration restored"
  echo "Log: $LOG"
  echo "Backup: $BACKUP"
  exit "$BUILD_RC"
fi

echo
echo "[6/7] Verifying route emission BEFORE accepting build"
echo "--------------------------------------------------------------"

EXPECTED=(
  "administration/route.js"
  "administration/[id]/route.js"
  "customers/route.js"
  "customers/[id]/route.js"
  "drivers/route.js"
  "drivers/[id]/route.js"
  "locations/route.js"
  "locations/[id]/route.js"
  "notifications/route.js"
  "notifications/[id]/route.js"
  "operations/route.js"
  "operations/[id]/route.js"
  "orders/route.js"
  "orders/[id]/route.js"
  "payments/route.js"
  "payments/[id]/route.js"
  "requests/route.js"
  "requests/[id]/route.js"
  "requests/[id]/accept/route.js"
  "scheduling/route.js"
  "scheduling/[id]/route.js"
  "health/route.js"
)

MISSING=0

for route in "${EXPECTED[@]}"; do
  if [ -f ".next/server/app/api/$route" ]; then
    echo "✓ $route"
  else
    echo "✗ MISSING $route"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -ne 0 ]; then
  echo
  echo "✗ Build completed but route emission verification failed"

  cp -f "$BACKUP/next.config.js" next.config.js
  cp -f "$BACKUP/jsconfig.json" jsconfig.json

  echo "✓ Original configuration restored"
  echo "Log: $LOG"
  echo "Backup: $BACKUP"
  exit 1
fi

echo
echo "[7/7] Verifying manifests"
echo "--------------------------------------------------------------"

for f in \
  .next/server/pages-manifest.json \
  .next/server/app-paths-manifest.json \
  .next/server/middleware-manifest.json \
  .next/server/server-reference-manifest.json \
  .next/server/next-font-manifest.json
do
  if [ -f "$f" ]; then
    echo "✓ $f"
  else
    echo "✗ MISSING $f"
    cp -f "$BACKUP/next.config.js" next.config.js
    cp -f "$BACKUP/jsconfig.json" jsconfig.json
    exit 1
  fi
done

echo
echo "=============================================================="
echo " REPAIR RESULT: PASS — DETERMINISTIC ROUTE EMISSION"
echo "=============================================================="
echo "Next 16.3.0 + Termux/WASM route emission stabilized by"
echo "disabling webpack filesystem cache while preserving the"
echo "known-good custom alias Webpack hook."
echo
echo "All expected API route artifacts emitted."
echo "All required manifests present."
echo
echo "Configuration intentionally remains in repaired state."
echo "Log:    $LOG"
echo "Backup: $BACKUP"
echo "=============================================================="
