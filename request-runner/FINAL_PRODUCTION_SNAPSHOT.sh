#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

bad() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo "=============================================================="
echo " REQUEST RUNNER® — FINAL PRODUCTION SNAPSHOT"
echo "=============================================================="

echo
echo "[1] ENTRYPOINT"
echo "--------------------------------------------------------------"
[ -x bin/doctor.js ] && ok "Doctor executable" || bad "Doctor executable"
head -n 1 bin/doctor.js | grep -q '^#!.*node' &&
    ok "Node.js shebang" ||
    bad "Node.js shebang"

echo
echo "[2] DOCTOR"
echo "--------------------------------------------------------------"
./bin/doctor.js >/dev/null 2>&1 &&
    ok "Platform doctor" ||
    bad "Platform doctor"

echo
echo "[3] TESTS"
echo "--------------------------------------------------------------"
node tests/run.js >/dev/null 2>&1 &&
    ok "Platform tests" ||
    bad "Platform tests"

echo
echo "[4] HTTP"
echo "--------------------------------------------------------------"

for url in \
    "http://127.0.0.1:3000/" \
    "http://127.0.0.1:3000/request" \
    "http://127.0.0.1:3000/ops" \
    "http://127.0.0.1:3000/api/health" \
    "http://127.0.0.1:3001/health"
do
    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        --max-time 5 "$url" 2>/dev/null || true)"

    case "$code" in
        2*|3*) ok "$url → HTTP $code" ;;
        *) bad "$url → HTTP ${code:-000}" ;;
    esac
done

echo
echo "[5] SOCKET.IO®"
echo "--------------------------------------------------------------"

SOCKET="$(
    curl -sS --max-time 5 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    2>/dev/null || true
)"

echo "$SOCKET" | grep -q '"sid"' &&
    ok "Socket.IO handshake" ||
    bad "Socket.IO handshake"

echo
echo "[6] RELEASE GATE"
echo "--------------------------------------------------------------"

./REQUEST_RUNNER_RELEASE_GATE.sh >/dev/null 2>&1 &&
    ok "Release gate GREEN" ||
    bad "Release gate RED"

echo
echo "=============================================================="
echo " FINAL SNAPSHOT RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST RUNNER® — PRODUCTION VERIFIED"
    echo "STATE: LOCKED / READY FOR NEXT PHASE"
else
    echo "STATUS: RED"
    echo "STOP — NO MUTATION"
    exit 1
fi

echo
echo "=============================================================="
