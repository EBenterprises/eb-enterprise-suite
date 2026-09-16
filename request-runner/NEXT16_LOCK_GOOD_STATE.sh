#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$HOME/request-runner" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/known-good-$STAMP"
LOG=".completion-logs/known-good-$STAMP.log"

mkdir -p "$BACKUP" .completion-logs

cp next.config.js "$BACKUP/next.config.js"
cp package.json "$BACKUP/package.json"
[ -f jsconfig.json ] && cp jsconfig.json "$BACKUP/jsconfig.json"
[ -f package-lock.json ] && cp package-lock.json "$BACKUP/package-lock.json"

exec > >(tee "$LOG") 2>&1

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT 16 KNOWN-GOOD STATE LOCK"
echo "=============================================================="
echo

echo "[1/5] Configuration fingerprint"
echo "--------------------------------------------------------------"

sha256sum next.config.js
echo

echo "[2/5] Verifying original alias hook"
echo "--------------------------------------------------------------"

grep -nE \
  'webpack:|config.resolve.alias|@framework|@app|allowedDevOrigins' \
  next.config.js

echo
echo "[3/5] Verifying generated manifests"
echo "--------------------------------------------------------------"

FAIL=0

for f in \
  .next/server/pages-manifest.json \
  .next/server/app-paths-manifest.json \
  .next/server/middleware-manifest.json
do
  if [ -f "$f" ]; then
    echo "✓ $f"
  else
    echo "✗ MISSING: $f"
    FAIL=1
  fi
done

echo
echo "[4/5] Verifying emitted API route artifacts"
echo "--------------------------------------------------------------"

ROUTES=(
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

for route in "${ROUTES[@]}"; do
  FILE=".next/server/app/api/$route"

  if [ -f "$FILE" ]; then
    echo "✓ $route"
  else
    echo "✗ MISSING: $route"
    FAIL=1
  fi
done

echo
echo "[5/5] Final state decision"
echo "--------------------------------------------------------------"

if [ "$FAIL" -eq 0 ]; then

  cat > .completion-known-good.json <<JSON
{
  "engine": "COMPLETION ENGINE®",
  "status": "KNOWN_GOOD",
  "next": "16.3.0",
  "build": "next build --webpack",
  "environment": "Termux/WASM",
  "webpackHook": "REQUIRED",
  "routeSource": "App Router",
  "sourceRewritesRequired": false,
  "manifestVerification": true,
  "apiArtifactVerification": true,
  "lockedAt": "$STAMP"
}
JSON

  echo "✓ ALL EXPECTED SERVER ARTIFACTS PRESENT"
  echo "✓ KNOWN-GOOD STATE RECORDED"
  echo
  echo "=============================================================="
  echo " STATE: LOCKED — PASS"
  echo "=============================================================="
  echo "Known-good marker: .completion-known-good.json"
  echo "Log: $LOG"
  echo "Backup: $BACKUP"
  echo "=============================================================="

  exit 0
fi

echo "✗ ARTIFACT VERIFICATION FAILED"
echo
echo "The configuration itself is preserved."
echo "Do not modify route source."
echo
echo "Log: $LOG"
echo "Backup: $BACKUP"
echo "=============================================================="

exit 1
