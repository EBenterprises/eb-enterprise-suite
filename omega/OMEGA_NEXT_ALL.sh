#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TOTAL=7
STEP=0

progress() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))
    printf "\n["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s\n" "$((STEP * 100 / TOTAL))" "$1"
}

pass() {
    echo "  PASS  $1"
}

fail() {
    echo "  FAIL  $1"
    exit 1
}

mkdir -p .omega/tmp .omega/certification

echo
echo "============================================================"
echo " OMEGA® — CONTINUE TO END STATE"
echo "============================================================"

progress "Verify project"
[ -f package.json ] || fail "package.json"
[ -d src/app ] || fail "src/app"
[ -f bin/omega.js ] || fail "CLI"
pass "project"

progress "Verify production artifact"
[ -d .next ] || fail "No .next artifact"
[ -f .next/BUILD_ID ] || fail "No Next BUILD_ID"
pass "production artifact"

progress "Verify runtime"
node bin/omega.js status >/dev/null 2>&1 || fail "CLI status"
node bin/omega.js capabilities >/dev/null 2>&1 || fail "CLI capabilities"
pass "CLI"

progress "Start production server"

PID_FILE=".omega/production.pid"
LOG=".omega/tmp/production.log"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    PID="$(cat "$PID_FILE")"
else
    pkill -f "next start" 2>/dev/null || true

    nohup npm run start -- --hostname 0.0.0.0 \
        > "$LOG" 2>&1 &

    PID=$!
    echo "$PID" > "$PID_FILE"
fi

READY=0

for _ in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

[ "$READY" -eq 1 ] || {
    tail -80 "$LOG" 2>/dev/null || true
    fail "server did not start"
}

pass "server"

progress "Verify HTTP application"

HTTP_CODE="$(
    curl -sS \
        -o .omega/tmp/home.html \
        -w '%{http_code}' \
        http://127.0.0.1:3000
)"

[ "$HTTP_CODE" = "200" ] || fail "HTTP $HTTP_CODE"
grep -qi "<html" .omega/tmp/home.html || fail "invalid HTML"

pass "HTTP 200"

progress "Record runtime state"

LAN_IP="$(
    ip route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
)"

{
    echo "OMEGA® RUNTIME STATE"
    echo "===================="
    echo
    echo "Status: RUNNING"
    echo "PID: $PID"
    echo "Local: http://127.0.0.1:3000"
    if [ -n "${LAN_IP:-}" ]; then
        echo "LAN: http://${LAN_IP}:3000"
    fi
    echo
    echo "Production artifact: VERIFIED"
    echo "HTTP response: 200"
    echo "Application HTML: VERIFIED"
    echo
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
} > .omega/certification/RUNTIME_STATE.txt

pass "runtime state"

progress "Complete"

echo
echo "============================================================"
echo "[########################################] 100%"
echo "============================================================"
echo
echo "OMEGA® — RUNNING"
echo
echo "LOCAL:"
echo "http://127.0.0.1:3000"

if [ -n "${LAN_IP:-}" ]; then
    echo
    echo "LAN:"
    echo "http://${LAN_IP}:3000"
fi

echo
echo "PID: $PID"
echo
echo "NEXT STATE: LIVE"
echo "============================================================"
