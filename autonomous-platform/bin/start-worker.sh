#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$ROOT/logs" "$ROOT/state"

if [ -f "$ROOT/state/worker.pid" ]; then
    PID="$(cat "$ROOT/state/worker.pid" 2>/dev/null || true)"

    if [ -n "$PID" ] &&
       kill -0 "$PID" 2>/dev/null; then
        echo "WORKER ALREADY RUNNING"
        exit 0
    fi

    rm -f "$ROOT/state/worker.pid"
fi

nohup node \
    "$ROOT/engine/autonomous-worker.js" \
    >>"$ROOT/logs/worker.stdout.log" \
    2>>"$ROOT/logs/worker.stderr.log" &

sleep 1

if [ -f "$ROOT/state/worker.pid" ]; then
    echo "AUTONOMOUS WORKER RUNNING"
    echo "PID: $(cat "$ROOT/state/worker.pid")"
else
    echo "WORKER FAILED TO START"
    exit 1
fi
