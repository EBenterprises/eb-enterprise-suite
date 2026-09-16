#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

RUNTIME="$ROOT/.runtime"
mkdir -p "$RUNTIME"

REALTIME_PID="$RUNTIME/realtime.pid"
REALTIME_LOG="$RUNTIME/realtime.log"
BACKUP="$ROOT/.realtime-repair-$(date +%Y%m%d-%H%M%S)"

echo
echo "=============================================================="
echo " EB PLATFORM® — REALTIME® FINAL REPAIR"
echo "=============================================================="
echo

echo "[1] LOCATE REALTIME SERVER"
echo "--------------------------------------------------------------"

ENTRY=""

for candidate in \
    "$ROOT/realtime-server.js" \
    "$ROOT/server-realtime.js" \
    "$ROOT/realtime/server.js" \
    "$ROOT/realtime/index.js"
do
    if [ -f "$candidate" ]; then
        ENTRY="$candidate"
        break
    fi
done

if [ -z "$ENTRY" ]; then
    echo "✗ No realtime server entrypoint found"
    exit 1
fi

echo "✓ Found: $ENTRY"

echo
echo "[2] BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

cp "$ENTRY" "$BACKUP/$(basename "$ENTRY")"
cp "$ROOT/EB_PLATFORM.sh" "$BACKUP/EB_PLATFORM.sh"

echo "✓ Backup: $BACKUP"

echo
echo "[3] SYNTAX CHECK"
echo "--------------------------------------------------------------"

node --check "$ENTRY"

echo "✓ Realtime server syntax valid"

echo
echo "[4] SOCKET.IO DEPENDENCIES"
echo "--------------------------------------------------------------"

node - <<'NODE'
const required = ["socket.io", "socket.io-client"];

for (const name of required) {
    try {
        console.log(`✓ ${name}: ${require.resolve(name)}`);
    } catch {
        console.error(`✗ ${name}: NOT FOUND`);
        process.exit(1);
    }
}
NODE

echo
echo "[5] INSPECT REALTIME CONFIG"
echo "--------------------------------------------------------------"

grep -nE \
    "3001|PORT|listen|new Server|socket\.io|createServer" \
    "$ENTRY" 2>/dev/null || true

echo
echo "[6] STOP OLD REALTIME PROCESS"
echo "--------------------------------------------------------------"

if [ -f "$REALTIME_PID" ]; then
    OLD_PID="$(cat "$REALTIME_PID" 2>/dev/null || true)"

    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
    fi

    rm -f "$REALTIME_PID"
fi

pkill -f "$ENTRY" 2>/dev/null || true
sleep 1

echo "✓ Old realtime process cleared"

echo
echo "[7] START REALTIME SERVER"
echo "--------------------------------------------------------------"

: > "$REALTIME_LOG"

nohup node "$ENTRY" \
    > "$REALTIME_LOG" 2>&1 &

REALTIME_LAUNCH_PID=$!

echo "$REALTIME_LAUNCH_PID" > "$REALTIME_PID"

echo "✓ Realtime process launched"
echo "  PID: $REALTIME_LAUNCH_PID"
echo "  LOG: $REALTIME_LOG"

echo
echo "[8] WAIT FOR PORT 3001"
echo "--------------------------------------------------------------"

READY=0

for i in $(seq 1 15); do
    if curl -fsS --max-time 2 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        > "$RUNTIME/socket-response" 2>/dev/null
    then
        READY=1
        break
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "✗ Realtime server did not become ready"
    echo
    echo "PID:"
    cat "$REALTIME_PID" 2>/dev/null || true
    echo
    echo "LOG:"
    tail -n 100 "$REALTIME_LOG" 2>/dev/null || true
    exit 1
fi

echo "✓ Port 3001 responding"

echo
echo "[9] ENGINE.IO HANDSHAKE"
echo "--------------------------------------------------------------"

SOCKET_RESPONSE="$(
    curl -fsS --max-time 5 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling"
)"

if printf '%s' "$SOCKET_RESPONSE" | grep -q '"sid"'; then
    echo "✓ Socket.IO® Engine.IO handshake successful"
else
    echo "✗ Handshake response did not contain sid"
    printf '%s\n' "$SOCKET_RESPONSE"
    exit 1
fi

echo
echo "[10] FIX EB_PLATFORM.SH"
echo "--------------------------------------------------------------"

python - "$ROOT/EB_PLATFORM.sh" "$ENTRY" <<'PY'
import sys
from pathlib import Path

platform = Path(sys.argv[1])
entry = Path(sys.argv[2])

src = platform.read_text()

old = '''    if [ -f "$ROOT/realtime/server.js" ]; then
        nohup node "$ROOT/realtime/server.js" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    elif [ -f "$ROOT/server-realtime.js" ]; then
        nohup node "$ROOT/server-realtime.js" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    else
        echo "⚠ No dedicated realtime server entrypoint found"
        return 0
    fi
'''

new = f'''    if [ -f "$ROOT/{entry.name}" ]; then
        nohup node "$ROOT/{entry.name}" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    elif [ -f "$ROOT/realtime/server.js" ]; then
        nohup node "$ROOT/realtime/server.js" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    elif [ -f "$ROOT/server-realtime.js" ]; then
        nohup node "$ROOT/server-realtime.js" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    else
        echo "⚠ No dedicated realtime server entrypoint found"
        return 0
    fi
'''

if old in src:
    src = src.replace(old, new)
else:
    print("⚠ Existing realtime launcher block differed; applying targeted repair")

    marker = '    echo "[1] Starting realtime server..."'
    start = src.find(marker)

    if start != -1:
        end = src.find('    sleep 1', start)

        if end != -1:
            replacement = f'''    echo "[1] Starting realtime server..."

    if [ -f "$ROOT/{entry.name}" ]; then
        nohup node "$ROOT/{entry.name}" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &
        echo $! > "$REALTIME_PID"
    elif [ -f "$ROOT/realtime/server.js" ]; then
        nohup node "$ROOT/realtime/server.js" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &
        echo $! > "$REALTIME_PID"
    elif [ -f "$ROOT/server-realtime.js" ]; then
        nohup node "$ROOT/server-realtime.js" \\
            > "$ROOT/.runtime/realtime.log" 2>&1 &
        echo $! > "$REALTIME_PID"
    else
        echo "⚠ No dedicated realtime server entrypoint found"
        return 0
    fi

'''
            src = src[:start] + replacement + src[end:]

platform.write_text(src)
PY

chmod 700 "$ROOT/EB_PLATFORM.sh"

bash -n "$ROOT/EB_PLATFORM.sh"

echo "✓ EB_PLATFORM.sh repaired"

echo
echo "[11] VERIFY PLATFORM STATUS"
echo "--------------------------------------------------------------"

"$ROOT/EB_PLATFORM.sh" status

echo
echo "[12] VERIFY APPLICATION"
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
            echo "✓ $route HTTP $code"
            ;;
        *)
            echo "✗ $route HTTP $code"
            exit 1
            ;;
    esac
done

echo
echo "[13] VERIFY EVENTBUS"
echo "--------------------------------------------------------------"

node - <<'NODE'
const { EventBus } = require("./framework");

const bus = new EventBus();
let received = false;

const handler = payload => {
    if (payload?.ok === true) {
        received = true;
    }
};

if (typeof bus.subscribe === "function") {
    bus.subscribe("eb.final.integration", handler);
} else if (typeof bus.on === "function") {
    bus.on("eb.final.integration", handler);
} else {
    throw new Error("EventBus has no subscription API");
}

if (typeof bus.publish === "function") {
    bus.publish("eb.final.integration", { ok: true });
} else if (typeof bus.emit === "function") {
    bus.emit("eb.final.integration", { ok: true });
} else {
    throw new Error("EventBus has no publish API");
}

if (!received) {
    throw new Error("EventBus round-trip failed");
}

console.log("✓ EventBus operational");
NODE

echo
echo "[14] FINAL REALTIME CHECK"
echo "--------------------------------------------------------------"

curl -fsS \
    --max-time 5 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    > "$RUNTIME/socket-response"

grep -q '"sid"' "$RUNTIME/socket-response"

echo "✓ Socket.IO® live on port 3001"

echo
echo "=============================================================="
echo " EB PLATFORM® — REALTIME REPAIR COMPLETE"
echo "=============================================================="
echo
echo "✓ Realtime entrypoint discovered"
echo "✓ Socket.IO dependencies verified"
echo "✓ Realtime server started"
echo "✓ Port 3001 verified"
echo "✓ Engine.IO handshake verified"
echo "✓ EB_PLATFORM.sh repaired"
echo "✓ Customer route verified"
echo "✓ Operations route verified"
echo "✓ EventBus verified"
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
echo "Backup:"
echo "  $BACKUP"
echo
echo "=============================================================="
