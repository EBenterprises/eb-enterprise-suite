#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/request-runner"
cd "$ROOT"

LOG="$ROOT/.steps35-40.log"
: > "$LOG"

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL + 1))
}

section() {
    echo
    echo "[$1] $2"
    echo "--------------------------------------------------------------"
}

http_check() {
    local name="$1"
    local url="$2"
    local code

    code="$(
        curl -sS \
            -o "$ROOT/.http-response" \
            -w '%{http_code}' \
            --max-time 8 \
            "$url" 2>/dev/null || true
    )"

    case "$code" in
        2*|3*) ok "$name — HTTP $code" ;;
        *) fail "$name — HTTP $code" ;;
    esac
}

echo "=============================================================="
echo " REQUEST RUNNER® — STEPS 35–40"
echo " PRODUCT VERIFICATION BUNDLE"
echo "=============================================================="

# ==============================================================
# STEP 35 — PRODUCT SURFACE
# ==============================================================

section "35" "PRODUCT SURFACE"

http_check \
    "Customer /request" \
    "http://127.0.0.1:3000/request"

http_check \
    "Operations /ops" \
    "http://127.0.0.1:3000/ops"

SOCKET_RESPONSE="$(
    curl -sS \
        --max-time 8 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        2>/dev/null || true
)"

if echo "$SOCKET_RESPONSE" | grep -q '"sid"'; then
    ok "Realtime Socket.IO handshake"
else
    fail "Realtime Socket.IO handshake"
fi

# ==============================================================
# STEP 36 — ROUTE INTEGRITY
# ==============================================================

section "36" "ROUTE INTEGRITY"

http_check \
    "Customer route" \
    "http://127.0.0.1:3000/request"

http_check \
    "Operations route" \
    "http://127.0.0.1:3000/ops"

if curl -fsS --max-time 8 \
    "http://127.0.0.1:3000/request" \
    2>/dev/null | grep -qiE 'request|customer|delivery'; then
    ok "Customer surface content detected"
else
    fail "Customer surface content not detected"
fi

if curl -fsS --max-time 8 \
    "http://127.0.0.1:3000/ops" \
    2>/dev/null | grep -qiE 'operation|dispatch|admin|request'; then
    ok "Operations surface content detected"
else
    fail "Operations surface content not detected"
fi

# ==============================================================
# STEP 37 — REALTIME
# ==============================================================

section "37" "REALTIME"

if echo "$SOCKET_RESPONSE" | grep -q '"sid"'; then
    ok "Engine.IO session established"
else
    fail "Engine.IO session unavailable"
fi

if echo "$SOCKET_RESPONSE" | grep -q '"upgrades"'; then
    ok "Realtime transport metadata present"
else
    fail "Realtime transport metadata missing"
fi

# ==============================================================
# STEP 38 — FRAMEWORK + MODULE INTEGRITY
# ==============================================================

section "38" "FRAMEWORK + MODULE INTEGRITY"

if node <<'NODE' >"$LOG" 2>&1
const platform = require("./framework");

const required = [
  "Application",
  "Container",
  "EventBus",
  "CommandBus",
  "QueryBus",
  "ModuleRegistry",
  "Pipeline",
  "Repository",
  "JsonRepository",
  "Entity",
  "Request",
  "Order",
  "Router",
  "RealtimeBus",
  "Authorization",
  "Audit",
  "Health",
  "environment",
  "config",
  "logger"
];

for (const name of required) {
    if (typeof platform[name] === "undefined") {
        throw new Error(`Missing framework export: ${name}`);
    }
}

console.log(`Framework exports: ${required.length}`);
NODE
then
    ok "Framework exports"
else
    fail "Framework exports"
    tail -n 20 "$LOG"
fi

if node <<'NODE' >"$LOG" 2>&1
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
const missing = required.filter(name => !names.includes(name));

if (missing.length) {
    throw new Error(`Missing modules: ${missing.join(", ")}`);
}

console.log(`Product modules: ${modules.length}`);
NODE
then
    ok "11 Request Runner® modules"
else
    fail "Request Runner® modules"
    tail -n 20 "$LOG"
fi

if node <<'NODE' >"$LOG" 2>&1
const { Request, Order } = require("./framework");

const request = new Request({
    id: "steps35-40-request",
    status: "pending"
});

const order = new Order({
    id: "steps35-40-order",
    status: "pending"
});

if (!request || !order) {
    throw new Error("Domain instantiation failed");
}

console.log("Request + Order instantiated");
NODE
then
    ok "Domain entities"
else
    fail "Domain entities"
    tail -n 20 "$LOG"
fi

# ==============================================================
# STEP 39 — RELEASE GATE
# ==============================================================

section "39" "RELEASE GATE"

if ./REQUEST_RUNNER_RELEASE_GATE.sh >"$LOG" 2>&1; then
    ok "Release gate GREEN"
else
    fail "Release gate RED"
    tail -n 30 "$LOG"
fi

# ==============================================================
# STEP 40 — FINAL LIVE SMOKE
# ==============================================================

section "40" "FINAL LIVE SMOKE TEST"

if ./EB_PLATFORM.sh status >"$LOG" 2>&1; then
    if grep -qE "Customer.*HEALTHY|Request Runner.*RUNNING" "$LOG"; then
        ok "Request Runner® running"
    else
        fail "Request Runner® status unavailable"
    fi

    if grep -qE "Realtime.*HEALTHY|Realtime.*RUNNING" "$LOG"; then
        ok "Realtime® running"
    else
        fail "Realtime® status unavailable"
    fi
else
    fail "Platform status command failed"
    tail -n 30 "$LOG"
fi

http_check \
    "Final customer endpoint" \
    "http://127.0.0.1:3000/request"

http_check \
    "Final operations endpoint" \
    "http://127.0.0.1:3000/ops"

FINAL_SOCKET="$(
    curl -sS \
        --max-time 8 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        2>/dev/null || true
)"

if echo "$FINAL_SOCKET" | grep -q '"sid"'; then
    ok "Final realtime endpoint"
else
    fail "Final realtime endpoint"
fi

rm -f "$ROOT/.http-response"

echo
echo "=============================================================="
echo " REQUEST RUNNER® — STEPS 35–40 RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "STEPS 35–40 VERIFIED"
    exit 0
else
    echo "STATUS: RED"
    echo "PIPELINE STOPPED"
    exit 1
fi
