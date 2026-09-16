#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/request-runner"
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

check() {
    local name="$1"
    local url="$2"
    local code

    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        --max-time 8 "$url" 2>/dev/null || true)"

    case "$code" in
        2*|3*) ok "$name — HTTP $code" ;;
        *) fail "$name — HTTP $code" ;;
    esac
}

echo "=== REQUEST RUNNER® — STEP 35 PRODUCT SURFACE ==="
echo

echo "[1] CUSTOMER SURFACE"
check "Customer /request" \
    "http://127.0.0.1:3000/request"

echo
echo "[2] OPERATIONS SURFACE"
check "Operations /ops" \
    "http://127.0.0.1:3000/ops"

echo
echo "[3] REALTIME SURFACE"

SOCKET="$(
    curl -sS --max-time 8 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    2>/dev/null || true
)"

if echo "$SOCKET" | grep -q '"sid"'; then
    ok "Socket.IO handshake"
else
    fail "Socket.IO handshake"
fi

echo
echo "[4] APPLICATION MODULES"

node <<'NODE'
const modules = require("./apps/request-runner");

const required = [
  "customers",
  "requests",
  "orders",
  "dispatch",
  "drivers",
  "locations",
  "scheduling",
  "payments",
  "notifications",
  "operations",
  "administration"
];

const names = modules.map(m => m.name);
const missing = required.filter(x => !names.includes(x));

if (missing.length) {
    console.error("Missing:", missing.join(", "));
    process.exit(1);
}

console.log(`✓ ${required.length} product modules loaded`);
NODE

PASS=$((PASS+1))

echo
echo "[5] RELEASE GATE"

if ./REQUEST_RUNNER_RELEASE_GATE.sh >"$ROOT/.step35-release.log" 2>&1; then
    ok "Release gate GREEN"
else
    fail "Release gate failed"
    tail -n 20 "$ROOT/.step35-release.log"
fi

echo
echo "=============================================================="
echo " STEP 35 RESULT"
echo "=============================================================="
echo "PASS: $PASS"
echo "FAIL: $FAIL"

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "PRODUCT SURFACE VERIFIED"
else
    echo "STATUS: RED"
    exit 1
fi
