#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT" || exit 1

if [ ! -f state/project.json ]; then
    echo "NO PROJECT"
    exit 1
fi

if [ -f state/engine.pid ]; then
    PID="$(cat state/engine.pid 2>/dev/null || true)"

    if [ -n "$PID" ] &&
       kill -0 "$PID" 2>/dev/null; then
        echo "ENGINE ALREADY RUNNING"
        exit 0
    fi

    rm -f state/engine.pid
fi

nohup node bin/run.js \
    >> logs/engine.stdout.log \
    2>> logs/engine.stderr.log &

echo $! > state/launcher.pid

sleep 1

if [ -f state/engine.pid ]; then
    echo "AUTONOMOUS ENGINE RUNNING"
    echo "PID: $(cat state/engine.pid)"
else
    echo "ENGINE FAILED TO START"
    exit 1
fi
