#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
WARN=0

ok(){ echo "✓ $1"; PASS=$((PASS+1)); }
fail(){ echo "✗ $1"; FAIL=$((FAIL+1)); }
warn(){ echo "⚠ $1"; WARN=$((WARN+1)); }

http_check(){
    local name="$1"
    local url="$2"
    local code

    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        --max-time 10 "$url" 2>/dev/null || echo 000)"

    case "$code" in
        2*|3*) ok "$name — HTTP $code" ;;
        *) fail "$name — HTTP $code" ;;
    esac
}

echo
echo "=============================================================="
echo " EB PLATFORM® — FULL APPLICATION INTEGRATION"
echo "=============================================================="
echo

echo "[1] PLATFORM STATUS"
echo "--------------------------------------------------------------"

./EB_PLATFORM.sh status

echo
echo "[2] PROCESS / PORT VERIFICATION"
echo "--------------------------------------------------------------"

if curl -fsS --max-time 5 http://127.0.0.1:3000 >/dev/null; then
    ok "Application port 3000 reachable"
else
    fail "Application port 3000 unreachable"
fi

if curl -fsS --max-time 5 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    >/tmp/eb-socket-response 2>/dev/null; then

    if grep -q '"sid"' /tmp/eb-socket-response; then
        ok "Socket.IO® Engine.IO handshake successful"
    else
        warn "Realtime HTTP endpoint responded without detectable sid"
    fi
else
    fail "Socket.IO® endpoint unreachable"
fi

echo
echo "[3] APPLICATION ROUTES"
echo "--------------------------------------------------------------"

http_check "Customer /request" \
    "http://127.0.0.1:3000/request"

http_check "Operations /ops" \
    "http://127.0.0.1:3000/ops"

echo
echo "[4] APPLICATION CONTENT"
echo "--------------------------------------------------------------"

CUSTOMER_HTML="$(curl -fsS --max-time 10 \
    http://127.0.0.1:3000/request 2>/dev/null || true)"

OPS_HTML="$(curl -fsS --max-time 10 \
    http://127.0.0.1:3000/ops 2>/dev/null || true)"

if [ -n "$CUSTOMER_HTML" ]; then
    ok "Customer application returned content"
else
    fail "Customer application returned empty content"
fi

if [ -n "$OPS_HTML" ]; then
    ok "Operations application returned content"
else
    fail "Operations application returned empty content"
fi

echo
echo "[5] PLATFORM DOCTOR"
echo "--------------------------------------------------------------"

if node ./bin/doctor.js; then
    ok "Platform doctor passed"
else
    fail "Platform doctor failed"
fi

echo
echo "[6] PLATFORM TEST SUITE"
echo "--------------------------------------------------------------"

if node ./tests/run.js; then
    ok "Platform tests passed"
else
    fail "Platform tests failed"
fi

echo
echo "[7] FRAMEWORK RUNTIME"
echo "--------------------------------------------------------------"

if node <<'NODE'
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
        console.error(`Missing framework export: ${name}`);
        process.exit(1);
    }
}

console.log(`Verified ${required.length} framework exports`);
NODE
then
    ok "Framework runtime loaded"
else
    fail "Framework runtime failed"
fi

echo
echo "[8] APPLICATION MODULES"
echo "--------------------------------------------------------------"

if node <<'NODE'
const modules = require("./apps/request-runner");

const expected = [
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

for (const name of expected) {
    if (!names.includes(name)) {
        console.error(`Missing application module: ${name}`);
        process.exit(1);
    }
}

console.log(`Verified ${modules.length} Request Runner® modules`);
NODE
then
    ok "All application modules loaded"
else
    fail "Application module loading failed"
fi

echo
echo "[9] DOMAIN RUNTIME"
echo "--------------------------------------------------------------"

if node <<'NODE'
const { Request, Order } = require("./framework");

const request = new Request({
    id: "integration-request",
    status: "pending"
});

const order = new Order({
    id: "integration-order",
    status: "pending"
});

if (!request || !order) process.exit(1);

console.log("Request entity:", request.id);
console.log("Order entity:", order.id);
NODE
then
    ok "Request/Order domain entities instantiated"
else
    fail "Domain entity instantiation failed"
fi

echo
echo "[10] EVENT INFRASTRUCTURE"
echo "--------------------------------------------------------------"

if node <<'NODE'
const { EventBus } = require("./framework");

const bus = new EventBus();
let received = false;

bus.subscribe("eb.integration.test", payload => {
    if (payload && payload.ok === true) received = true;
});

bus.publish("eb.integration.test", {
    ok: true,
    source: "NEXT_EB_INTEGRATION"
});

if (!received) process.exit(1);

console.log("Event publish/subscribe successful");
NODE
then
    ok "Event bus operational"
else
    fail "Event bus failed"
fi

echo
echo "[11] COMMAND / QUERY INFRASTRUCTURE"
echo "--------------------------------------------------------------"

if node <<'NODE'
const { CommandBus, QueryBus } = require("./framework");

const commands = new CommandBus();
const queries = new QueryBus();

let commandOK = false;
let queryOK = false;

commands.register("eb.integration.command", () => {
    commandOK = true;
    return { ok: true };
});

queries.register("eb.integration.query", () => {
    queryOK = true;
    return { ok: true };
});

commands.execute("eb.integration.command");
queries.execute("eb.integration.query");

if (!commandOK || !queryOK) process.exit(1);

console.log("Command execution successful");
console.log("Query execution successful");
NODE
then
    ok "Command/query buses operational"
else
    fail "Command/query infrastructure failed"
fi

echo
echo "[12] SECURITY / AUDIT"
echo "--------------------------------------------------------------"

if node <<'NODE'
const platform = require("./framework");

if (
    typeof platform.Authorization === "undefined" ||
    typeof platform.Audit === "undefined"
) {
    process.exit(1);
}

console.log("Authorization loaded");
console.log("Audit loaded");
NODE
then
    ok "Security infrastructure operational"
else
    fail "Security infrastructure failed"
fi

echo
echo "[13] FILESYSTEM"
echo "--------------------------------------------------------------"

REQUIRED_FILES=(
    package.json
    server.js
    next.config.js
    run-request-runner.sh
    EB_PLATFORM.sh
    framework/index.js
    framework/core/application.js
    framework/core/container/index.js
    framework/core/events/event-bus.js
    framework/core/commands/command-bus.js
    framework/core/queries/query-bus.js
    framework/data/repository.js
    framework/realtime/realtime-bus.js
    framework/security/authorization.js
    framework/security/audit.js
    bin/eb
    bin/status.js
    bin/doctor.js
    tests/run.js
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        ok "File: $file"
    else
        fail "Missing: $file"
    fi
done

echo
echo "[14] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

SYNTAX_FAILED=0

while IFS= read -r file; do
    if ! node --check "$file" >/dev/null 2>&1; then
        fail "Syntax: $file"
        SYNTAX_FAILED=1
    fi
done < <(find framework apps bin tests -type f -name '*.js' 2>/dev/null | sort)

if [ "$SYNTAX_FAILED" -eq 0 ]; then
    ok "All JavaScript files passed syntax validation"
fi

echo
echo "[15] LAN ACCESS"
echo "--------------------------------------------------------------"

LAN_IP="$(
    ip -4 addr show 2>/dev/null |
    awk '/inet / && $2 !~ /^127\./ {
        split($2,a,"/");
        print a[1];
        exit
    }' || true
)"

LAN_IP="${LAN_IP:-127.0.0.1}"

http_check "LAN Customer /request" \
    "http://${LAN_IP}:3000/request"

http_check "LAN Operations /ops" \
    "http://${LAN_IP}:3000/ops"

echo
echo "=============================================================="
echo " EB PLATFORM® — INTEGRATION RESULT"
echo "=============================================================="
echo
echo "PASS : $PASS"
echo "FAIL : $FAIL"
echo "WARN : $WARN"
echo
echo "Customer:"
echo "  http://${LAN_IP}:3000/request"
echo
echo "Operations:"
echo "  http://${LAN_IP}:3000/ops"
echo
echo "Realtime:"
echo "  http://${LAN_IP}:3001"
echo
echo "=============================================================="

rm -f /tmp/eb-socket-response

if [ "$FAIL" -eq 0 ]; then
    echo "✓ FULL INTEGRATION PASSED"
    echo "=============================================================="
    exit 0
else
    echo "✗ INTEGRATION REQUIRES ATTENTION"
    echo "=============================================================="
    exit 1
fi
