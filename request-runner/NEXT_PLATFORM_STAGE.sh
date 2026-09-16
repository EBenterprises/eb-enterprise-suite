#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

RUNTIME="$ROOT/.runtime"
mkdir -p "$RUNTIME"

PASS=0
FAIL=0
WARN=0

ok()   { echo "✓ $1"; PASS=$((PASS+1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL+1)); }
warn() { echo "⚠ $1"; WARN=$((WARN+1)); }

echo
echo "=============================================================="
echo " EB PLATFORM® — NEXT INTEGRATION STAGE"
echo "=============================================================="
echo

echo "[1] STOP/START CONTROL"
echo "--------------------------------------------------------------"

if ./EB_PLATFORM.sh status >/dev/null 2>&1; then
    ok "Platform control script operational"
else
    fail "Platform status command failed"
fi

echo
echo "[2] HTTP ROUTES"
echo "--------------------------------------------------------------"

for route in /request /ops; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        --max-time 8 \
        "http://127.0.0.1:3000${route}" 2>/dev/null || echo 000)"

    case "$code" in
        2*|3*) ok "${route} HTTP ${code}" ;;
        *) fail "${route} HTTP ${code}" ;;
    esac
done

echo
echo "[3] REALTIME HANDSHAKE"
echo "--------------------------------------------------------------"

socket_response="$(
    curl -sS --max-time 8 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    2>/dev/null || true
)"

if printf '%s' "$socket_response" | grep -q '"sid"'; then
    ok "Socket.IO Engine.IO handshake"
else
    warn "Socket.IO handshake not verified"
fi

echo
echo "[4] FRAMEWORK"
echo "--------------------------------------------------------------"

node <<'NODE'
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
    console.error(`MISSING: ${name}`);
    process.exit(1);
  }
}

console.log(`Framework exports: ${required.length}/${required.length}`);
NODE

if [ "$?" -eq 0 ]; then
    ok "Framework exports verified"
else
    fail "Framework exports failed"
fi

echo
echo "[5] APPLICATION MODULES"
echo "--------------------------------------------------------------"

node <<'NODE'
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
    console.error(`MISSING MODULE: ${name}`);
    process.exit(1);
  }
}

console.log(`Modules: ${names.length}/${expected.length}`);
NODE

if [ "$?" -eq 0 ]; then
    ok "All application modules verified"
else
    fail "Application module verification failed"
fi

echo
echo "[6] DOMAIN"
echo "--------------------------------------------------------------"

node <<'NODE'
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

console.log("Request:", request.id);
console.log("Order:", order.id);
NODE

if [ "$?" -eq 0 ]; then
    ok "Domain entities operational"
else
    fail "Domain entity test failed"
fi

echo
echo "[7] EVENT INFRASTRUCTURE"
echo "--------------------------------------------------------------"

node <<'NODE'
const { EventBus } = require("./framework");

const bus = new EventBus();
let received = false;

bus.subscribe("platform.integration.test", () => {
  received = true;
});

bus.publish("platform.integration.test", {
  source: "NEXT_PLATFORM_STAGE",
  timestamp: Date.now()
});

if (!received) process.exit(1);

console.log("Event bus round-trip successful");
NODE

if [ "$?" -eq 0 ]; then
    ok "Event bus operational"
else
    fail "Event bus failed"
fi

echo
echo "[8] COMMAND / QUERY INFRASTRUCTURE"
echo "--------------------------------------------------------------"

node <<'NODE'
const { CommandBus, QueryBus } = require("./framework");

const commands = new CommandBus();
const queries = new QueryBus();

let commandOK = false;
let queryOK = false;

commands.register("integration.command", () => {
  commandOK = true;
  return { ok: true };
});

queries.register("integration.query", () => {
  queryOK = true;
  return { ok: true };
});

commands.execute("integration.command");
queries.execute("integration.query");

if (!commandOK || !queryOK) process.exit(1);

console.log("Command bus round-trip successful");
console.log("Query bus round-trip successful");
NODE

if [ "$?" -eq 0 ]; then
    ok "Command/query infrastructure operational"
else
    fail "Command/query infrastructure failed"
fi

echo
echo "[9] SECURITY"
echo "--------------------------------------------------------------"

node <<'NODE'
const { Authorization, Audit } = require("./framework");

if (!Authorization || !Audit) process.exit(1);

console.log("Authorization loaded");
console.log("Audit loaded");
NODE

if [ "$?" -eq 0 ]; then
    ok "Security infrastructure operational"
else
    fail "Security infrastructure failed"
fi

echo
echo "[10] HEALTH"
echo "--------------------------------------------------------------"

node <<'NODE'
const { Health } = require("./framework");

if (!Health) process.exit(1);

console.log("Health subsystem loaded");
NODE

if [ "$?" -eq 0 ]; then
    ok "Health subsystem operational"
else
    fail "Health subsystem failed"
fi

echo
echo "[11] CLI"
echo "--------------------------------------------------------------"

for command in status doctor test; do
    if ./bin/eb "$command" >/dev/null 2>&1; then
        ok "eb $command"
    else
        fail "eb $command"
    fi
done

echo
echo "[12] LAUNCHER"
echo "--------------------------------------------------------------"

for file in \
    EB_PLATFORM.sh \
    start.sh \
    launch.sh \
    run-request-runner.sh
do
    if [ -x "$file" ]; then
        ok "$file executable"
    else
        fail "$file missing or not executable"
    fi
done

echo
echo "[13] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

syntax_failed=0

while IFS= read -r file; do
    case "$file" in
        ./.next/*|./node_modules/*|./.platform-backup-*/*)
            continue
            ;;
    esac

    if ! node --check "$file" >/dev/null 2>&1; then
        echo "✗ Syntax: $file"
        syntax_failed=1
    fi
done < <(find framework apps bin tests -type f -name '*.js' 2>/dev/null | sort)

if [ "$syntax_failed" -eq 0 ]; then
    ok "JavaScript syntax clean"
else
    fail "JavaScript syntax errors detected"
fi

echo
echo "[14] PLATFORM TEST SUITE"
echo "--------------------------------------------------------------"

if node ./tests/run.js; then
    ok "Platform tests passed"
else
    fail "Platform tests failed"
fi

echo
echo "[15] FINAL STATUS"
echo "--------------------------------------------------------------"

./EB_PLATFORM.sh status

echo
echo "=============================================================="
echo " EB PLATFORM® — NEXT STAGE COMPLETE"
echo "=============================================================="
echo
echo "PASS : $PASS"
echo "WARN : $WARN"
echo "FAIL : $FAIL"
echo

if [ "$FAIL" -gt 0 ]; then
    echo "✗ INTEGRATION STAGE FAILED"
    exit 1
fi

echo "✓ INTEGRATION STAGE PASSED"
echo
echo "Application:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "Realtime:"
echo "  http://127.0.0.1:3001"
echo
echo "LAN:"
LAN_IP="$(
    ip -4 addr show 2>/dev/null |
    awk '/inet / && $2 !~ /^127\./ {split($2,a,"/"); print a[1]; exit}'
)"

if [ -z "${LAN_IP:-}" ]; then
    LAN_IP="127.0.0.1"
fi

echo "  http://${LAN_IP}:3000"
echo
