#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

if [ ! -f .autonomous/background.pid ]; then
    echo "SUPERVISOR PID NOT FOUND"
    exit 0
fi

PID="$(cat .autonomous/background.pid 2>/dev/null || true)"

if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    echo "REQUEST RUNNER® AUTONOMOUS SUPERVISOR STOPPED: $PID"
else
    echo "SUPERVISOR IS NOT RUNNING"
fi

rm -f .autonomous/supervisor.lock
