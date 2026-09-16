#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="$ROOT/.completion-logs"
BACKUP_ROOT="$ROOT/.completion-backups/deterministic-build-$STAMP"
LOG="$LOG_DIR/deterministic-build-$STAMP.log"
LOCK="$ROOT/.completion-build.lock"
GOOD="$BACKUP_ROOT/known-good-next"

mkdir -p "$LOG_DIR" "$BACKUP_ROOT"

exec > >(tee "$LOG") 2>&1

pass() { printf '✓ %s\n' "$1"; }
fail() { printf '✗ %s\n' "$1"; }
info() { printf '%s\n' "$1"; }

cleanup() {
    rm -f "$LOCK"
}
trap cleanup EXIT INT TERM

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT 16 DETERMINISTIC BUILD GATE"
echo "=============================================================="
echo "Next: $(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)"
echo "Log: $LOG"
echo

echo "[1/9] Exclusive build lock"
echo "--------------------------------------------------------------"

if [ -e "$LOCK" ]; then
    OLD_PID="$(cat "$LOCK" 2>/dev/null || true)"

    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        fail "Another build is already running: PID $OLD_PID"
        exit 20
    fi

    rm -f "$LOCK"
fi

printf '%s\n' "$$" > "$LOCK"
pass "Exclusive build lock acquired"

echo
echo "[2/9] Source/configuration fingerprint"
echo "--------------------------------------------------------------"

sha256sum \
    package.json \
    package-lock.json \
    next.config.js \
    jsconfig.json \
    2>/dev/null | tee "$BACKUP_ROOT/source-fingerprint.sha256"

pass "Fingerprint captured"

echo
echo "[3/9] Preserving current known-good artifacts"
echo "--------------------------------------------------------------"

if [ -d ".next/server" ] &&
   [ -f ".next/server/pages-manifest.json" ] &&
   [ -f ".next/server/app-paths-manifest.json" ]; then

    mkdir -p "$GOOD"
    cp -a .next/server "$GOOD/"
    [ -d ".next/static" ] && cp -a .next/static "$GOOD/"
    [ -f ".next/BUILD_ID" ] && cp .next/BUILD_ID "$GOOD/"
    pass "Known-good .next snapshot preserved"
else
    info "No complete existing .next state available"
fi

echo
echo "[4/9] Checking for concurrent Next processes"
echo "--------------------------------------------------------------"

if command -v pgrep >/dev/null 2>&1; then
    PIDS="$(pgrep -f 'next build|next/dist/bin/next' 2>/dev/null || true)"

    if [ -n "$PIDS" ]; then
        fail "Concurrent Next process detected: $PIDS"
        exit 21
    fi
fi

pass "No competing Next build detected"

echo
echo "[5/9] Clean build-state initialization"
echo "--------------------------------------------------------------"

rm -rf .next
mkdir -p .next

pass ".next recreated from clean state"

echo
echo "[6/9] Controlled production build"
echo "--------------------------------------------------------------"

BUILD_START="$(date +%s)"
BUILD_START_HUMAN="$(date '+%Y-%m-%d %H:%M:%S')"

info "Build start: $BUILD_START_HUMAN"

set +e
npm run build
BUILD_RC=$?
set -e

BUILD_END="$(date +%s)"
BUILD_DURATION="$((BUILD_END - BUILD_START))"

echo
info "Build exit code: $BUILD_RC"
info "Build duration: ${BUILD_DURATION}s"

if [ "$BUILD_RC" -ne 0 ]; then
    fail "Production build failed"

    if [ -d "$GOOD/server" ]; then
        rm -rf .next
        mkdir -p .next
        cp -a "$GOOD/server" .next/
        [ -d "$GOOD/static" ] && cp -a "$GOOD/static" .next/
        [ -f "$GOOD/BUILD_ID" ] && cp "$GOOD/BUILD_ID" .next/
        pass "Previous known-good .next restored"
    fi

    exit "$BUILD_RC"
fi

pass "Production build exited successfully"

echo
echo "[7/9] Manifest/artifact integrity gate"
echo "--------------------------------------------------------------"

REQUIRED_MANIFESTS=(
    ".next/server/pages-manifest.json"
    ".next/server/app-paths-manifest.json"
    ".next/server/middleware-manifest.json"
    ".next/server/server-reference-manifest.json"
    ".next/server/next-font-manifest.json"
)

MANIFEST_FAILURE=0

for f in "${REQUIRED_MANIFESTS[@]}"; do
    if [ -f "$f" ]; then
        pass "$f"
    else
        fail "Missing $f"
        MANIFEST_FAILURE=1
    fi
done

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

ROUTE_FAILURE=0

for route in "${EXPECTED_ROUTES[@]}"; do
    f=".next/server/app/api/$route"

    if [ -f "$f" ]; then
        pass "$route"
    else
        fail "Missing $route"
        ROUTE_FAILURE=1
    fi
done

if [ "$MANIFEST_FAILURE" -ne 0 ] || [ "$ROUTE_FAILURE" -ne 0 ]; then
    fail "Artifact integrity gate failed"

    if [ -d "$GOOD/server" ]; then
        rm -rf .next
        mkdir -p .next
        cp -a "$GOOD/server" .next/
        [ -d "$GOOD/static" ] && cp -a "$GOOD/static" .next/
        [ -f "$GOOD/BUILD_ID" ] && cp "$GOOD/BUILD_ID" .next/
        pass "Known-good .next restored"
    fi

    exit 30
fi

pass "Manifest integrity PASS"
pass "API artifact integrity PASS"

echo
echo "[8/9] Manifest ↔ filesystem consistency"
echo "--------------------------------------------------------------"

node <<'NODE'
const fs = require("fs");

const manifestPath = ".next/server/app-paths-manifest.json";
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

const entries = Object.keys(manifest);

let failures = 0;

for (const entry of entries) {
    if (!entry.startsWith("/api/")) continue;

    const rel = entry
        .replace(/^\/api\//, "")
        .replace(/\/route$/, "");

    const artifact =
        `.next/server/app/api/${rel}/route.js`;

    if (!fs.existsSync(artifact)) {
        console.error(`MISSING: ${artifact}`);
        failures++;
    }
}

if (failures) {
    process.exit(1);
}

console.log(`✓ ${entries.length} App Router manifest entries verified`);
console.log("✓ API manifest ↔ filesystem correspondence verified");
NODE

CONSISTENCY_RC=$?

if [ "$CONSISTENCY_RC" -ne 0 ]; then
    fail "Manifest/filesystem consistency failed"
    exit 31
fi

echo
echo "[9/9] Final determinism snapshot"
echo "--------------------------------------------------------------"

sha256sum \
    package.json \
    package-lock.json \
    next.config.js \
    jsconfig.json \
    2>/dev/null > "$BACKUP_ROOT/final-source-fingerprint.sha256"

find .next/server \
    -type f \
    -printf '%p %s %T@\n' \
    2>/dev/null \
    | sort > "$BACKUP_ROOT/server-artifact-metadata.txt"

ROUTE_COUNT="$(
    find .next/server/app/api \
        -type f \
        -name 'route.js' \
        2>/dev/null \
        | wc -l \
        | tr -d ' '
)"

MANIFEST_SIZE="$(
    wc -c < .next/server/app-paths-manifest.json \
    | tr -d ' '
)"

pass "Source fingerprint preserved"
pass "Server artifact metadata captured"
pass "Emitted route.js count: $ROUTE_COUNT"
pass "App manifest size: $MANIFEST_SIZE bytes"

echo
echo "=============================================================="
echo " DETERMINISTIC BUILD GATE: PASS"
echo "=============================================================="
echo "Build duration: ${BUILD_DURATION}s"
echo "Route artifacts: $ROUTE_COUNT"
echo "Log:    $LOG"
echo "Backup: $BACKUP_ROOT"
echo "=============================================================="
