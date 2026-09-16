#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="COMPLETION_ENGINE_ADAPTIVE_V4"
STATE=".completion-state"
LOGDIR=".completion-logs"
BACKUP=".completion-backups"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/adaptive-v4-$TS.log"
KNOWN_GOOD="$STATE/known-good.json"
LOCK="$STATE/.lock"

mkdir -p "$STATE" "$LOGDIR" "$BACKUP"

exec > >(tee "$LOG") 2>&1

cleanup() {
    rm -f "$LOCK"
}
trap cleanup EXIT INT TERM

if [ -e "$LOCK" ]; then
    echo "✗ Another Completion Engine® run is active."
    exit 1
fi

touch "$LOCK"

echo "=============================================================="
echo " COMPLETION ENGINE® — ADAPTIVE V4"
echo "=============================================================="
echo "Next: $(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)"
echo "Node: $(node -v 2>/dev/null || echo unknown)"
echo "Log:  $LOG"
echo "=============================================================="
echo

sha() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo "unavailable"
    fi
}

record_known_good() {
    cat > "$KNOWN_GOOD" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "status": "KNOWN_GOOD",
  "next": "$(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)",
  "node": "$(node -v 2>/dev/null || echo unknown)",
  "package": "$(sha package.json)",
  "lockfile": "$(sha package-lock.json)",
  "next_config": "$(sha next.config.js)",
  "jsconfig": "$(sha jsconfig.json)",
  "route_artifacts": $EMITTED,
  "build_exit_code": $BUILD_RC,
  "build_duration_seconds": $DURATION
}
JSON
}

EXPECTED_ROUTES=(
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

echo "[1/8] ENVIRONMENT CONTRACT"
echo "--------------------------------------------------------------"

if ! command -v node >/dev/null 2>&1; then
    echo "✗ Node.js unavailable"
    exit 2
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "✗ npm unavailable"
    exit 2
fi

if [ ! -d node_modules/next ]; then
    echo "✗ Next.js installation missing"
    exit 2
fi

echo "✓ Node available"
echo "✓ npm available"
echo "✓ Next.js installation available"

echo
echo "[2/8] SOURCE CONTRACT"
echo "--------------------------------------------------------------"

SOURCE_FAILURE=0

for route in "${EXPECTED_ROUTES[@]}"; do
    if [ ! -f "app/api/$route" ]; then
        echo "✗ Missing source: app/api/$route"
        SOURCE_FAILURE=1
    fi
done

if [ -f "framework/api/crud-route.js" ]; then
    echo "✓ CRUD contract exists"
else
    echo "✗ CRUD contract missing"
    SOURCE_FAILURE=1
fi

if grep -q '"@framework/\*"' jsconfig.json 2>/dev/null; then
    echo "✓ @framework alias exists"
else
    echo "✗ @framework alias missing"
    SOURCE_FAILURE=1
fi

if grep -q '"@app/\*"' jsconfig.json 2>/dev/null; then
    echo "✓ @app alias exists"
else
    echo "✗ @app alias missing"
    SOURCE_FAILURE=1
fi

if [ "$SOURCE_FAILURE" -ne 0 ]; then
    echo
    echo "✗ Source contract failed."
    echo "No speculative production repair will be attempted."
    exit 2
fi

echo "✓ Complete source contract verified"

echo
echo "[3/8] HISTORICAL FAILURE CORRELATION"
echo "--------------------------------------------------------------"

ORIGINAL_LOG=""

for candidate in \
    "$LOGDIR"/deterministic-build-*.log \
    "$LOGDIR"/wasm-route-emission-*.log
do
    if [ -f "$candidate" ]; then
        ORIGINAL_LOG="$candidate"
        break
    fi
done

if [ -n "$ORIGINAL_LOG" ]; then
    echo "Evidence log: $ORIGINAL_LOG"

    if grep -qE \
        'Cannot find module .*\.next/server/app/.*/route\.js|Failed to collect page data' \
        "$ORIGINAL_LOG"; then
        echo "✓ Historical server-artifact emission failure confirmed"
        HISTORICAL_FAILURE="SERVER_ARTIFACT_EMISSION_FAILURE"
    else
        HISTORICAL_FAILURE="NONE"
        echo "• No original route-emission failure signature found"
    fi
else
    HISTORICAL_FAILURE="NONE"
    echo "• No deterministic historical failure log found"
fi

echo
echo "[4/8] CURRENT ARTIFACT EVIDENCE"
echo "--------------------------------------------------------------"

EMITTED=0
MISSING=0

for route in "${EXPECTED_ROUTES[@]}"; do
    if [ -f ".next/server/app/api/$route" ]; then
        EMITTED=$((EMITTED + 1))
    else
        MISSING=$((MISSING + 1))
    fi
done

echo "Expected routes : ${#EXPECTED_ROUTES[@]}"
echo "Emitted routes  : $EMITTED"
echo "Missing routes  : $MISSING"

if [ "$EMITTED" -eq "${#EXPECTED_ROUTES[@]}" ]; then
    echo "✓ All expected API route artifacts exist"
else
    echo "✗ Route artifact set incomplete"
fi

echo
echo "[5/8] REQUIRED MANIFEST CONTRACT"
echo "--------------------------------------------------------------"

MANIFEST_FAILURE=0

for manifest in \
    ".next/server/app-paths-manifest.json" \
    ".next/server/pages-manifest.json" \
    ".next/server/middleware-manifest.json" \
    ".next/server/server-reference-manifest.json"
do
    if [ -f "$manifest" ]; then
        echo "✓ $manifest"
    else
        echo "✗ MISSING $manifest"
        MANIFEST_FAILURE=1
    fi
done

echo
echo "Optional Next/font artifact:"
if [ -f ".next/server/next-font-manifest.json" ]; then
    echo "✓ present"
else
    echo "• absent — not an acceptance failure for this build"
fi

echo
echo "[6/8] BUILD VERIFICATION"
echo "--------------------------------------------------------------"

echo "Running exactly ONE production build."
echo "No blind retries."
echo "No route-source mutation."
echo "No alias mutation."
echo

rm -rf .next

BUILD_START="$(date +%s)"

if npm run build -- --webpack; then
    BUILD_RC=0
else
    BUILD_RC=$?
fi

BUILD_END="$(date +%s)"
DURATION=$((BUILD_END - BUILD_START))

echo
echo "Build exit code: $BUILD_RC"
echo "Build duration : ${DURATION}s"

echo
echo "[7/8] POST-BUILD ROUTE GATE"
echo "--------------------------------------------------------------"

EMITTED=0
MISSING=0

for route in "${EXPECTED_ROUTES[@]}"; do
    if [ -f ".next/server/app/api/$route" ]; then
        EMITTED=$((EMITTED + 1))
    else
        MISSING=$((MISSING + 1))
        echo "✗ MISSING: $route"
    fi
done

echo
echo "Routes emitted: $EMITTED/${#EXPECTED_ROUTES[@]}"

POST_MANIFEST_FAILURE=0

for manifest in \
    ".next/server/app-paths-manifest.json" \
    ".next/server/pages-manifest.json" \
    ".next/server/middleware-manifest.json" \
    ".next/server/server-reference-manifest.json"
do
    if [ ! -f "$manifest" ]; then
        POST_MANIFEST_FAILURE=1
    fi
done

echo
echo "[8/8] COMPLETION DECISION"
echo "--------------------------------------------------------------"

if [ "$BUILD_RC" -eq 0 ] &&
   [ "$EMITTED" -eq "${#EXPECTED_ROUTES[@]}" ] &&
   [ "$POST_MANIFEST_FAILURE" -eq 0 ]; then

    record_known_good

    cp -f next.config.js \
        "$BACKUP/next.config.known-good-$TS.js"

    cp -f jsconfig.json \
        "$BACKUP/jsconfig.known-good-$TS.json"

    echo "✓ Production build passed"
    echo "✓ All 22 API route artifacts emitted"
    echo "✓ Required manifests emitted"
    echo "✓ Optional next-font-manifest correctly excluded from hard gate"
    echo "✓ Known-good state recorded"
    echo
    echo "=============================================================="
    echo " COMPLETION ENGINE® — GATE PASS"
    echo "=============================================================="
    echo "STATUS: PRODUCTION BUILD VERIFIED"
    echo "Routes: $EMITTED/${#EXPECTED_ROUTES[@]}"
    echo "Build:  ${DURATION}s"
    echo "State:  $KNOWN_GOOD"
    echo "Log:    $LOG"
    echo "=============================================================="

    exit 0
fi

echo "✗ Production completion gate failed"

if [ "$BUILD_RC" -ne 0 ]; then
    echo "Failure: production build exit code $BUILD_RC"
fi

if [ "$MISSING" -ne 0 ]; then
    echo "Failure: $MISSING route artifacts missing"
fi

if [ "$POST_MANIFEST_FAILURE" -ne 0 ]; then
    echo "Failure: required manifest missing"
fi

echo
echo "Historical classification: $HISTORICAL_FAILURE"
echo "No destructive source rewrite performed."
echo "Log: $LOG"

exit "${BUILD_RC:-1}"
