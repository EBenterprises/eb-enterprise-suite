#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

RUNTIME="$ROOT/.runtime"
mkdir -p "$RUNTIME"

echo
echo "=============================================================="
echo " EB PLATFORM® — FINAL SYSTEM VERIFICATION"
echo "=============================================================="
echo

echo "[1] CURRENT STATUS"
echo "--------------------------------------------------------------"
./EB_PLATFORM.sh status

echo
echo "[2] REALTIME DIRECT CHECK"
echo "--------------------------------------------------------------"

RESPONSE="$(
    curl -fsS --max-time 5 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling"
)"

if printf '%s' "$RESPONSE" | grep -q '"sid"'; then
    echo "✓ Socket.IO® handshake: PASS"
else
    echo "✗ Socket.IO® handshake: FAIL"
    printf '%s\n' "$RESPONSE"
    exit 1
fi

echo
echo "[3] APPLICATION ROUTES"
echo "--------------------------------------------------------------"

for route in /request /ops; do
    code="$(
        curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 8 \
        "http://127.0.0.1:3000${route}" \
        2>/dev/null || true
    )"

    case "$code" in
        2*|3*)
            echo "✓ $route : HTTP $code"
            ;;
        *)
            echo "✗ $route : HTTP $code"
            exit 1
            ;;
    esac
done

echo
echo "[4] EVENTBUS"
echo "--------------------------------------------------------------"

node - <<'NODE'
const { EventBus } = require("./framework");

const bus = new EventBus();
let received = false;

const handler = payload => {
    if (payload && payload.ok === true) {
        received = true;
    }
};

if (typeof bus.subscribe === "function") {
    bus.subscribe("eb.final.verify", handler);
} else {
    bus.on("eb.final.verify", handler);
}

if (typeof bus.publish === "function") {
    bus.publish("eb.final.verify", { ok: true });
} else {
    bus.emit("eb.final.verify", { ok: true });
}

if (!received) {
    throw new Error("EventBus round-trip failed");
}

console.log("✓ EventBus round-trip: PASS");
NODE

echo
echo "[5] FRAMEWORK TESTS"
echo "--------------------------------------------------------------"

node ./tests/run.js

echo
echo "[6] APPLICATION MODULES"
echo "--------------------------------------------------------------"

node - <<'NODE'
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
        throw new Error(`Missing module: ${name}`);
    }
}

console.log(`✓ Request Runner® modules: ${names.length}/${expected.length}`);
NODE

echo
echo "[7] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

while IFS= read -r file; do
    case "$file" in
        ./.next/*|./node_modules/*|./.platform-backup-*/*|./.repair-backup-*/*)
            continue
            ;;
    esac

    node --check "$file" >/dev/null
done < <(
    find framework apps bin tests -type f -name '*.js' 2>/dev/null | sort
)

echo "✓ JavaScript syntax: PASS"

echo
echo "[8] REALTIME PROCESS"
echo "--------------------------------------------------------------"

if [ -f "$RUNTIME/realtime.pid" ]; then
    PID="$(cat "$RUNTIME/realtime.pid")"

    if kill -0 "$PID" 2>/dev/null; then
        echo "✓ Realtime® PID $PID alive"
    else
        echo "✗ Realtime® PID $PID is dead"
        exit 1
    fi
else
    echo "✗ realtime.pid missing"
    exit 1
fi

echo
echo "[9] PORT 3001"
echo "--------------------------------------------------------------"

if command -v ss >/dev/null 2>&1; then
    if ss -ltn 2>/dev/null | grep -q ':3001'; then
        echo "✓ Port 3001 listening"
    else
        echo "✗ Port 3001 not listening"
        exit 1
    fi
else
    echo "⚠ ss unavailable; HTTP verification already passed"
fi

echo
echo "[10] PLATFORM DOCTOR"
echo "--------------------------------------------------------------"

node ./bin/doctor.js

echo
echo "=============================================================="
echo " EB PLATFORM® — FINAL VERIFICATION PASSED"
echo "=============================================================="
echo
echo "Customer:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "Realtime:"
echo "  http://127.0.0.1:3001"
echo
echo "=============================================================="
