#!/bin/bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DPID_FILE="$ROOT_DIR/var/run/daemon.pid"
SPID_FILE="$ROOT_DIR/var/run/supervisor.pid"

case "$1" in
    start)
        bash "$ROOT_DIR/bin/launch.sh"
        nohup bash "$ROOT_DIR/bin/supervisor.sh" >/dev/null 2>&1 &
        echo "Enterprise stack deployed and supervised."
        ;;
    stop)
        [ -f "$SPID_FILE" ] && kill -9 "$(cat "$SPID_FILE")" 2>/dev/null && rm -f "$SPID_FILE"
        [ -f "$DPID_FILE" ] && kill -15 "$(cat "$DPID_FILE")" 2>/dev/null && rm -f "$DPID_FILE"
        pkill -9 -f "daemon.py"
        pkill -9 -f "supervisor.sh"
        echo "Enterprise stack halted."
        ;;
    test)
        python3 -m unittest discover -s tests
        ;;
    status)
        if [ -f "$DPID_FILE" ] && ps -p "$(cat "$DPID_FILE")" > /dev/null 2>&1; then
            echo "Daemon: RUNNING (PID: $(cat "$DPID_FILE"))"
        else
            echo "Daemon: STOPPED"
        fi
        if [ -f "$SPID_FILE" ] && ps -p "$(cat "$SPID_FILE")" > /dev/null 2>&1; then
            echo "Supervisor: RUNNING (PID: $(cat "$SPID_FILE"))"
        else
            echo "Supervisor: STOPPED"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|test|status}"
        exit 1
        ;;
esac
