#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

if [ -f .autonomous/COMPLETE ]; then
    echo "REQUEST RUNNER® AUTONOMOUS BUILD IS ALREADY COMPLETE."
    exit 0
fi

if [ -f .autonomous/supervisor.lock ]; then
    PID="$(cat .autonomous/supervisor.lock 2>/dev/null || true)"

    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "REQUEST RUNNER® AUTONOMOUS SUPERVISOR ALREADY RUNNING: PID $PID"
        exit 0
    fi

    rm -f .autonomous/supervisor.lock
fi

mkdir -p .autonomous

nohup ./AUTONOMOUS_REQUEST_RUNNER_V2.sh \
    > .autonomous/console.log \
    2>&1 < /dev/null &

PID=$!

echo "$PID" > .autonomous/background.pid

echo "=============================================================="
echo " REQUEST RUNNER® — AUTONOMOUS ENGINE LAUNCHED"
echo "=============================================================="
echo
echo "PID:       $PID"
echo "Console:   .autonomous/console.log"
echo "Journal:   .autonomous/journal.log"
echo "State:     .autonomous/state.json"
echo "Lock:      .autonomous/supervisor.lock"
echo
echo "It will continue without this terminal session."
echo "It will checkpoint progress and resume from verified phases."
echo "=============================================================="
