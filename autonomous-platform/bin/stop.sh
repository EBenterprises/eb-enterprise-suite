#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$ROOT/state/engine.pid" ]; then
    PID="$(cat "$ROOT/state/engine.pid" 2>/dev/null || true)"

    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
    fi
fi

rm -f \
    "$ROOT/state/engine.pid" \
    "$ROOT/state/launcher.pid"

echo "AUTONOMOUS ENGINE STOPPED"
