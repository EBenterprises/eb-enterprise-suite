#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

echo "=============================================================="
echo " REQUEST RUNNER® — AUTONOMOUS STATUS"
echo "=============================================================="
echo

if [ -f .autonomous/state.json ]; then
    cat .autonomous/state.json
else
    echo "STATUS: NOT STARTED"
fi

echo

if [ -f .autonomous/background.pid ]; then
    PID="$(cat .autonomous/background.pid 2>/dev/null || true)"

    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "SUPERVISOR: RUNNING"
        echo "PID: $PID"
    else
        echo "SUPERVISOR: STOPPED"
    fi
fi

echo

if [ -f .autonomous/COMPLETE ]; then
    echo "BUILD: COMPLETE"
else
    echo "BUILD: IN PROGRESS"
fi

echo
echo "=============================================================="
