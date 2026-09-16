#!/usr/bin/env bash
# ==============================================================================
# Executive Spectrum - Master Orchestrator Daemon Script
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

WORKSPACE_DIR="$HOME/termux_workspace"
VAULT_DIR="$WORKSPACE_DIR/.vault"
PID_FILE="$VAULT_DIR/orchestrator.pid"
LOG_FILE="$WORKSPACE_DIR/orchestrator.log"

mkdir -p "$VAULT_DIR"

start_daemon() {
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            echo "[!] Orchestrator daemon is already running (PID: $OLD_PID)."
            return 0
        fi
    fi

    echo "[+] Starting Executive Spectrum background daemons..."
    
    # Spawn background monitor loop
    (
        while true; do
            python3 "$WORKSPACE_DIR/workspace_scheduler.py" >> "$LOG_FILE" 2>&1
            sleep 300
        done
    ) &
    
    NEW_PID=$!
    echo "$NEW_PID" > "$PID_FILE"
    echo "[+] Daemons started successfully (PID: $NEW_PID)."
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            rm -f "$PID_FILE"
            echo "[+] Orchestrator daemon stopped (PID: $PID)."
            return 0
        fi
        rm -f "$PID_FILE"
    fi
    echo "[!] No running orchestrator daemon found."
}

status_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "Daemon Status: RUNNING (PID: $PID)"
            return 0
        fi
    fi
    echo "Daemon Status: STOPPED"
}

case "$1" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        start_daemon
        ;;
    status)
        status_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
