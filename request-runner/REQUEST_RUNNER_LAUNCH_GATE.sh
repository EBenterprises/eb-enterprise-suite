#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

PORT="${REQUEST_RUNNER_PORT:-3100}"
TMP="$ROOT/.launch-gate"
LOG="$TMP/server.log"
PID=""

rm -rf "$TMP"
mkdir -p "$TMP"

cleanup() {
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
        wait "$PID" 2>/dev/null || true
    fi
    rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
    echo "✗ $*"
    echo "=== REQUEST RUNNER® — LAUNCH GATE FAILED ==="
    exit 1
}

echo "=== REQUEST RUNNER® — LAUNCH GATE ==="

echo "[1] RELEASE GATE"
./REQUEST_RUNNER_RELEASE_GATE.sh >/dev/null 2>&1 || fail "release gate"
echo "✓ Release gate"

echo "[2] START"
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
    fail "server startup"
}

echo "✓ Production server :$PORT"

echo "[3] HEALTH"
node - "$TMP/health.json" <<'NODE' || fail "health contract"
const fs=require("fs");
const x=JSON.parse(fs.readFileSync(process.argv[2],"utf8"));

if(x.ok!==true) process.exit(1);
if(x.status!=="healthy") process.exit(1);

console.log("✓ healthy");
console.log("✓ persistence:",x.persistence||"unknown");
NODE

echo "[4] API"
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
    code="$(curl -sS \
        --connect-timeout 3 \
        -o "$TMP/response" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT/api/$endpoint" || true)"

    case "$code" in
        2??|3??) echo "✓ $endpoint [$code]" ;;
        *) fail "API /$endpoint [$code]" ;;
    esac
done

echo "[5] FRONTEND"
for route in / /request /requests /orders /drivers /ops; do
    code="$(curl -sS \
        --connect-timeout 3 \
        -o "$TMP/page" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT$route" || true)"

    case "$code" in
        2??|3??) echo "✓ $route [$code]" ;;
        *) fail "frontend $route [$code]" ;;
    esac
done

echo "[6] SERVER LOG"
if grep -Eqi \
    '(^|[^a-z])(fatal|unhandled|uncaught exception)([^a-z]|$)' \
    "$LOG" 2>/dev/null
then
    tail -30 "$LOG"
    fail "fatal/unhandled server error"
fi
echo "✓ No fatal/unhandled errors"

echo "[7] FINAL TEST"
npm run eb:test >/dev/null 2>&1 || fail "final tests"
echo "✓ Tests passed"

echo
echo "=== REQUEST RUNNER® — LAUNCH GATE PASSED ==="
echo "STATUS: GREEN"
echo "LIVE: http://127.0.0.1:$PORT"
