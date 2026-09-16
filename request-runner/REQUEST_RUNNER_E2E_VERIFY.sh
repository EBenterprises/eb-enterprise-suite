#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

PORT="${REQUEST_RUNNER_PORT:-3100}"
TMP="$ROOT/.e2e-runtime"
LOG="$TMP/server.log"
HEALTH="$TMP/health.json"
RESPONSE="$TMP/response"
PAGE="$TMP/page"
PID=""

rm -rf "$TMP"
mkdir -p "$TMP"

cleanup() {
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
        wait "$PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "=== REQUEST RUNNER® — LIVE E2E VERIFICATION ==="

echo "[1] CORE"
npm run eb:doctor >/dev/null || {
    echo "✗ Doctor failed"
    exit 1
}
npm run eb:test >/dev/null || {
    echo "✗ Tests failed"
    exit 1
}
echo "✓ Doctor"
echo "✓ Tests"

echo "[2] PRODUCTION SERVER"
PORT="$PORT" npm start >"$LOG" 2>&1 &
PID=$!

READY=0

for i in $(seq 1 30); do
    if curl -fsS \
        --connect-timeout 1 \
        "http://127.0.0.1:$PORT/api/health" \
        >"$HEALTH" 2>/dev/null; then
        READY=1
        break
    fi
    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "✗ Server did not become ready"
    echo "--- SERVER LOG ---"
    tail -30 "$LOG" 2>/dev/null || true
    exit 1
fi

echo "✓ Server ready :$PORT"

echo "[3] HEALTH"
if node -e '
const fs=require("fs");
const x=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
if (x.status && x.status !== "ok" && x.health?.status !== "ok") process.exit(1);
' "$HEALTH" 2>/dev/null; then
    echo "✓ Health response valid"
else
    echo "! Health endpoint returned:"
    head -c 1000 "$HEALTH"
    echo
fi

echo "[4] API SURFACE"

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
        -o "$RESPONSE" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT/api/$endpoint" || true)"

    case "$CODE" in
        2??|3??)
            echo "✓ /api/$endpoint [$CODE]"
            ;;
        *)
            echo "✗ /api/$endpoint [$CODE]"
            FAILED=1
            ;;
    esac
done

echo "[5] FRONTEND SURFACE"

for route in / /request /requests /orders /drivers /ops; do
    CODE="$(curl -sS \
        --connect-timeout 3 \
        -o "$PAGE" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT$route" || true)"

    case "$CODE" in
        2??|3??)
            echo "✓ $route [$CODE]"
            ;;
        *)
            echo "✗ $route [$CODE]"
            FAILED=1
            ;;
    esac
done

echo "[6] SERVER ERRORS"

if grep -Eqi \
    '(^|[^a-z])(fatal|unhandled|uncaught exception)([^a-z]|$)' \
    "$LOG" 2>/dev/null; then
    echo "! Fatal/unhandled entry detected"
    tail -30 "$LOG"
    FAILED=1
else
    echo "✓ No fatal/unhandled entries"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "=== REQUEST RUNNER® — E2E VERIFICATION PASSED ==="
else
    echo "=== REQUEST RUNNER® — E2E VERIFICATION FAILED ==="
    echo "Runtime artifacts: $TMP"
    exit 1
fi
