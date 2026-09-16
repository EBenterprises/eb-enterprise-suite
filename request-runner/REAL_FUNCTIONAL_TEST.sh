#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo
echo "=============================================================="
echo " EB PLATFORM® — REAL FUNCTIONAL TEST"
echo "=============================================================="
echo

echo "[1] START PLATFORM"
./EB_PLATFORM.sh start || true

sleep 2

echo
echo "[2] HEALTH"

if curl -fsS http://127.0.0.1:3000/api/health >/dev/null; then
    ok "API health"
else
    fail "API health"
fi

if curl -fsS http://127.0.0.1:3001/health >/dev/null; then
    ok "Realtime health"
else
    fail "Realtime health"
fi

echo
echo "[3] SOCKET.IO HANDSHAKE"

SOCKET="$(
    curl -fsS \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling"
)"

if printf '%s' "$SOCKET" | grep -q '"sid"'; then
    ok "Engine.IO handshake"
else
    fail "Engine.IO handshake"
fi

echo
echo "[4] REAL CUSTOMER CREATION"

CUSTOMER_RESPONSE="$(
    curl -fsS \
    -X POST \
    -H 'Content-Type: application/json' \
    -d '{"name":"Integration Customer","phone":"0000000000"}' \
    http://127.0.0.1:3000/api/customers
)"

CUSTOMER_ID="$(
    printf '%s' "$CUSTOMER_RESPONSE" |
    node -e '
        let s="";
        process.stdin.on("data",d=>s+=d);
        process.stdin.on("end",()=>{
            const x=JSON.parse(s);
            process.stdout.write(String(x.data.id));
        });
    '
)"

if [ -n "$CUSTOMER_ID" ]; then
    ok "Customer persisted: $CUSTOMER_ID"
else
    fail "Customer creation"
fi

echo
echo "[5] REAL REQUEST CREATION"

REQUEST_RESPONSE="$(
    curl -fsS \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"customerId\":\"$CUSTOMER_ID\",\"pickup\":\"Test Pickup\",\"destination\":\"Test Destination\"}" \
    http://127.0.0.1:3000/api/requests
)"

REQUEST_ID="$(
    printf '%s' "$REQUEST_RESPONSE" |
    node -e '
        let s="";
        process.stdin.on("data",d=>s+=d);
        process.stdin.on("end",()=>{
            const x=JSON.parse(s);
            process.stdout.write(String(x.data.id));
        });
    '
)"

if [ -n "$REQUEST_ID" ]; then
    ok "Request persisted: $REQUEST_ID"
else
    fail "Request creation"
fi

echo
echo "[6] REAL REQUEST ACCEPTANCE"

ORDER_RESPONSE="$(
    curl -fsS \
    -X POST \
    http://127.0.0.1:3000/api/requests/"$REQUEST_ID"/accept
)"

ORDER_ID="$(
    printf '%s' "$ORDER_RESPONSE" |
    node -e '
        let s="";
        process.stdin.on("data",d=>s+=d);
        process.stdin.on("end",()=>{
            const x=JSON.parse(s);
            process.stdout.write(String(x.order.id));
        });
    '
)"

if [ -n "$ORDER_ID" ]; then
    ok "Order created from request: $ORDER_ID"
else
    fail "Order creation"
fi

echo
echo "[7] REAL STATUS TRANSITION"

STATUS_RESPONSE="$(
    curl -fsS \
    -X PATCH \
    -H 'Content-Type: application/json' \
    -d '{"status":"completed"}' \
    http://127.0.0.1:3000/api/requests/"$REQUEST_ID"/status
)"

if printf '%s' "$STATUS_RESPONSE" | grep -q '"completed"'; then
    ok "Request status persisted"
else
    fail "Request status transition"
fi

echo
echo "[8] PERSISTENCE VERIFICATION"

if grep -q "$CUSTOMER_ID" data/customers.json; then
    ok "Customer exists on disk"
else
    fail "Customer persistence"
fi

if grep -q "$REQUEST_ID" data/requests.json; then
    ok "Request exists on disk"
else
    fail "Request persistence"
fi

if grep -q "$ORDER_ID" data/orders.json; then
    ok "Order exists on disk"
else
    fail "Order persistence"
fi

echo
echo "[9] FRAMEWORK TESTS"

if node tests/run.js >/dev/null; then
    ok "Framework test suite"
else
    fail "Framework test suite"
fi

echo
echo "[10] STATUS"

./EB_PLATFORM.sh status

echo
echo "=============================================================="
echo " REAL FUNCTIONAL RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "✓ EVERYTHING REAL — CORE FLOW VERIFIED"
    exit 0
fi

echo "✗ REAL FUNCTIONAL TEST FAILED"
exit 1
