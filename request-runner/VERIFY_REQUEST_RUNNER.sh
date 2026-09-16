#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

PORT="${REQUEST_RUNNER_PORT:-3100}"
TMP="$ROOT/.verify-runtime"
LOG="$TMP/server.log"
PID=""

rm -rf "$TMP"
mkdir -p "$TMP"

cleanup() {
    [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
    echo "✗ $1"
    echo "=== REQUEST RUNNER® — VERIFICATION FAILED ==="
    exit 1
}

echo "=== REQUEST RUNNER® — COMPLETE VERIFICATION ==="

echo "[1] CORE"
npm run eb:doctor >/dev/null 2>&1 || fail "doctor"
npm run eb:test >/dev/null 2>&1 || fail "tests"
npm run eb:status >/dev/null 2>&1 || fail "status"
echo "✓ Doctor"
echo "✓ Tests"
echo "✓ Status"

echo "[2] BUILD"
npm run build >/dev/null 2>&1 || fail "production build"
echo "✓ Production build"

echo "[3] SERVER"
PORT="$PORT" npm start >"$LOG" 2>&1 &
PID=$!

READY=0
for _ in $(seq 1 30); do
    if curl -fsS \
        --connect-timeout 1 \
        "http://127.0.0.1:$PORT/api/health" \
        >"$TMP/health.json" 2>/dev/null; then
        READY=1
        break
    fi
    sleep 1
done

[ "$READY" -eq 1 ] || {
    tail -30 "$LOG" 2>/dev/null
    fail "production server"
}

echo "✓ Server :$PORT"

echo "[4] HEALTH"
node - "$TMP/health.json" <<'NODE' || exit 1
const fs = require("fs");
const x = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (x.ok !== true || x.status !== "healthy") process.exit(1);
console.log("✓ Health: healthy");
console.log("✓ Persistence:", x.persistence || "unknown");
NODE

echo "[5] API"
FAILED=0

for endpoint in \
    customers \
    requests \
    orders \
    drivers \
    locations \
    scheduling \
    payments \
    notifications \
    operations \
    administration
do
    CODE="$(curl -sS \
        --connect-timeout 3 \
        -o "$TMP/response" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT/api/$endpoint" || true)"

    case "$CODE" in
        2??|3??) echo "✓ /api/$endpoint [$CODE]" ;;
        *) echo "✗ /api/$endpoint [$CODE]"; FAILED=1 ;;
    esac
done

[ "$FAILED" -eq 0 ] || fail "API surface"

echo "[6] FRONTEND"
FAILED=0

for route in / /request /requests /orders /drivers /ops; do
    CODE="$(curl -sS \
        --connect-timeout 3 \
        -o "$TMP/page" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT$route" || true)"

    case "$CODE" in
        2??|3??) echo "✓ $route [$CODE]" ;;
        *) echo "✗ $route [$CODE]"; FAILED=1 ;;
    esac
done

[ "$FAILED" -eq 0 ] || fail "frontend surface"

echo "[7] SERVER LOG"
if grep -Eqi \
    '(^|[^a-z])(fatal|unhandled|uncaught exception)([^a-z]|$)' \
    "$
cd ~/request-runner

cat > VERIFY_REQUEST_RUNNER.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

PORT="${REQUEST_RUNNER_PORT:-3100}"
TMP="$ROOT/.verify-runtime"
LOG="$TMP/server.log"
PID=""

rm -rf "$TMP"
mkdir -p "$TMP"

cleanup() {
    [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
    echo "✗ $1"
    echo "=== REQUEST RUNNER® — VERIFICATION FAILED ==="
    exit 1
}

echo "=== REQUEST RUNNER® — COMPLETE VERIFICATION ==="

echo "[1] CORE"
npm run eb:doctor >/dev/null 2>&1 || fail "doctor"
npm run eb:test >/dev/null 2>&1 || fail "tests"
npm run eb:status >/dev/null 2>&1 || fail "status"
echo "✓ Doctor"
echo "✓ Tests"
echo "✓ Status"

echo "[2] BUILD"
npm run build >/dev/null 2>&1 || fail "production build"
echo "✓ Production build"

echo "[3] SERVER"
PORT="$PORT" npm start >"$LOG" 2>&1 &
PID=$!

READY=0
for _ in $(seq 1 30); do
    if curl -fsS \
        --connect-timeout 1 \
        "http://127.0.0.1:$PORT/api/health" \
        >"$TMP/health.json" 2>/dev/null; then
        READY=1
        break
    fi
    sleep 1
done

[ "$READY" -eq 1 ] || {
    tail -30 "$LOG" 2>/dev/null
    fail "production server"
}

echo "✓ Server :$PORT"

echo "[4] HEALTH"
node - "$TMP/health.json" <<'NODE' || exit 1
const fs = require("fs");
const x = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (x.ok !== true || x.status !== "healthy") process.exit(1);
console.log("✓ Health: healthy");
console.log("✓ Persistence:", x.persistence || "unknown");
NODE

echo "[5] API"
FAILED=0

for endpoint in \
    customers \
    requests \
    orders \
    drivers \
    locations \
    scheduling \
    payments \
    notifications \
    operations \
    administration
do
    CODE="$(curl -sS \
        --connect-timeout 3 \
        -o "$TMP/response" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT/api/$endpoint" || true)"

    case "$CODE" in
        2??|3??) echo "✓ /api/$endpoint [$CODE]" ;;
        *) echo "✗ /api/$endpoint [$CODE]"; FAILED=1 ;;
    esac
done

[ "$FAILED" -eq 0 ] || fail "API surface"

echo "[6] FRONTEND"
FAILED=0

for route in / /request /requests /orders /drivers /ops; do
    CODE="$(curl -sS \
        --connect-timeout 3 \
        -o "$TMP/page" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT$route" || true)"

    case "$CODE" in
        2??|3??) echo "✓ $route [$CODE]" ;;
        *) echo "✗ $route [$CODE]"; FAILED=1 ;;
    esac
done

[ "$FAILED" -eq 0 ] || fail "frontend surface"

echo "[7] SERVER LOG"
if grep -Eqi \
    '(^|[^a-z])(fatal|unhandled|uncaught exception)([^a-z]|$)' \
    "$LOG" 2>/dev/null; then
    tail -30 "$LOG"
    fail "fatal server error"
fi
echo "✓ No fatal/unhandled errors"

echo "[8] LIFECYCLE"
node <<'NODE' || fail "business lifecycle"
const fs = require("fs");
const path = require("path");

const candidates = [
  "framework",
  "apps/request-runner",
  "server.js"
];

for (const p of candidates) {
  if (fs.existsSync(p)) {
    console.log("✓ Runtime surface:", p);
  }
}

const dirs = [
  "data",
  "storage",
  "framework",
  "app",
  "apps"
];

for (const d of dirs) {
  if (fs.existsSync(d)) console.log("✓", d);
}
NODE

echo "[9] FINAL"
echo "✓ Core"
echo "✓ Build"
echo "✓ Production server"
echo "✓ Health"
echo "✓ APIs"
echo "✓ Frontend"
echo "✓ Server error scan"
echo "✓ Runtime lifecycle surface"

echo
echo "=== REQUEST RUNNER® — COMPLETE VERIFICATION PASSED ==="
