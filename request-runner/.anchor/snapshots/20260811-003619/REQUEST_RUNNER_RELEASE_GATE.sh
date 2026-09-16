#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
LOG="$ROOT/.release-verify.log"

ok() {
    echo "✓ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL + 1))
}

run_check() {
    local name="$1"
    shift

    if "$@" >"$LOG" 2>&1; then
        ok "$name"
    else
        fail "$name"
        tail -n 20 "$LOG" 2>/dev/null || true
    fi
}

echo "=== REQUEST RUNNER® — RELEASE GATE ==="
echo

echo "[1] VERIFY"
echo "--------------------------------------------------------------"

if [ ! -f "$ROOT/MASS_COMPLETE_REQUEST_RUNNER.sh" ]; then
    fail "MASS_COMPLETE_REQUEST_RUNNER.sh missing"
else
    run_check "Mass completion verification" \
        bash "$ROOT/MASS_COMPLETE_REQUEST_RUNNER.sh"
fi

echo
echo "[2] PLATFORM FILES"
echo "--------------------------------------------------------------"

FILES=(
    "package.json"
    "server.js"
    "next.config.js"
    "EB_PLATFORM.sh"
    "start.sh"
    "launch.sh"
    "framework/index.js"
    "apps/request-runner/index.js"
    "bin/doctor.js"
    "tests/run.js"
)

for file in "${FILES[@]}"; do
    if [ -f "$ROOT/$file" ]; then
        ok "$file"
    else
        fail "Missing: $file"
    fi
done

echo
echo "[3] SHELL SYNTAX"
echo "--------------------------------------------------------------"

if bash -n "$ROOT/EB_PLATFORM.sh"; then
    ok "EB_PLATFORM.sh syntax"
else
    fail "EB_PLATFORM.sh syntax"
fi

if bash -n "$ROOT/start.sh"; then
    ok "start.sh syntax"
else
    fail "start.sh syntax"
fi

if bash -n "$ROOT/launch.sh"; then
    ok "launch.sh syntax"
else
    fail "launch.sh syntax"
fi

if bash -n "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh"; then
    ok "REQUEST_RUNNER_RELEASE_GATE.sh syntax"
else
    fail "REQUEST_RUNNER_RELEASE_GATE.sh syntax"
fi

echo
echo "[4] NODE RUNTIME"
echo "--------------------------------------------------------------"

if command -v node >/dev/null 2>&1; then
    ok "Node.js $(node --version)"
else
    fail "Node.js missing"
fi

if command -v npm >/dev/null 2>&1; then
    ok "npm available"
else
    fail "npm missing"
fi

if command -v curl >/dev/null 2>&1; then
    ok "curl available"
else
    fail "curl missing"
fi

echo
echo "[5] LIVE APPLICATION"
echo "--------------------------------------------------------------"

check_http() {
    local name="$1"
    local url="$2"
    local code

    code="$(
        curl -sS \
            -o "$ROOT/.release-http-response" \
            -w '%{http_code}' \
            --max-time 8 \
            "$url" 2>/dev/null || true
    )"

    case "$code" in
        2*|3*)
            ok "$name — HTTP $code"
            ;;
        *)
            fail "$name — HTTP $code"
            ;;
    esac
}

check_http \
    "Customer /request" \
    "http://127.0.0.1:3000/request"

check_http \
    "Operations /ops" \
    "http://127.0.0.1:3000/ops"

echo
echo "[6] REALTIME"
echo "--------------------------------------------------------------"

SOCKET_RESPONSE="$(
    curl -sS \
        --max-time 8 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        2>/dev/null || true
)"

if echo "$SOCKET_RESPONSE" | grep -q '"sid"'; then
    ok "Socket.IO handshake"
else
    fail "Socket.IO handshake"
fi

echo
echo "[7] PLATFORM DOCTOR"
echo "--------------------------------------------------------------"

if node "$ROOT/bin/doctor.js" >"$LOG" 2>&1; then
    ok "Platform doctor"
else
    fail "Platform doctor"
    tail -n 30 "$LOG" 2>/dev/null || true
fi

echo
echo "[8] PLATFORM TESTS"
echo "--------------------------------------------------------------"

if node "$ROOT/tests/run.js" >"$LOG" 2>&1; then
    ok "Platform tests"
else
    fail "Platform tests"
    tail -n 30 "$LOG" 2>/dev/null || true
fi

echo
echo "[9] FRAMEWORK LOAD"
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
        console.error("Missing export:", name);
        process.exit(1);
    }
}

console.log(`Framework exports verified: ${required.length}`);
NODE
then
    ok "Framework runtime exports"
else
    fail "Framework runtime exports"
fi

echo
echo "[10] APPLICATION MODULES"
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
        console.error("Missing module:", name);
        process.exit(1);
    }
}

console.log(`Application modules verified: ${modules.length}`);
NODE
then
    ok "Request Runner® modules"
else
    fail "Request Runner® modules"
fi

echo
echo "[11] DOMAIN"
echo "--------------------------------------------------------------"

if node <<'NODE'
const platform = require("./framework");

const request = new platform.Request({
    id: "release-gate-request",
    status: "pending"
});

const order = new platform.Order({
    id: "release-gate-order",
    status: "pending"
});

if (!request || !order) {
    process.exit(1);
}

console.log("Request entity instantiated");
console.log("Order entity instantiated");
NODE
then
    ok "Domain entities"
else
    fail "Domain entities"
fi

echo
echo "[12] EVENT BUS"
echo "--------------------------------------------------------------"

if node <<'NODE'
const { EventBus } = require("./framework");

const bus = new EventBus();
let received = false;

bus.subscribe("eb.release-gate", () => {
    received = true;
});

bus.publish("eb.release-gate", {
    source: "release-gate",
    timestamp: Date.now()
});

if (!received) process.exit(1);

console.log("Event bus verified");
NODE
then
    ok "Event bus"
else
    fail "Event bus"
fi

echo
echo "[13] COMMAND / QUERY BUS"
echo "--------------------------------------------------------------"

if node <<'NODE'
const { CommandBus, QueryBus } = require("./framework");

const commands = new CommandBus();
const queries = new QueryBus();

let commandRan = false;
let queryRan = false;

commands.register("eb.release.command", () => {
    commandRan = true;
    return { ok: true };
});

queries.register("eb.release.query", () => {
    queryRan = true;
    return { ok: true };
});

commands.execute("eb.release.command");
queries.execute("eb.release.query");

if (!commandRan || !queryRan) process.exit(1);

console.log("Command bus verified");
console.log("Query bus verified");
NODE
then
    ok "Command/query infrastructure"
else
    fail "Command/query infrastructure"
fi

echo
echo "[14] SECURITY"
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
    ok "Security subsystems"
else
    fail "Security subsystems"
fi

echo
echo "[15] BACKUPS"
echo "--------------------------------------------------------------"

BACKUPS="$(
    find "$ROOT" \
        -maxdepth 1 \
        -type d \
        -name '.platform-backup-*' \
        2>/dev/null | wc -l
)"

if [ "$BACKUPS" -gt 0 ]; then
    ok "$BACKUPS platform backup(s)"
else
    fail "No platform backup found"
fi

echo
echo "=============================================================="
echo " REQUEST RUNNER® — RELEASE GATE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST RUNNER® RELEASE READY"
    exit 0
else
    echo "STATUS: RED"
    echo "RELEASE BLOCKED"
    exit 1
fi
