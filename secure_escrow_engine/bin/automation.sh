#!/bin/bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT_DIR/bin/daemon.pid"

while true; do
    # Check if daemon is running and healthy
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ! ps -p "$PID" > /dev/null 2>&1; then
            echo "[$(date)] Daemon down! Restarting..."
            bash "$ROOT_DIR/bin/launch.sh"
        fi
    else
        echo "[$(date)] No PID file found. Launching daemon..."
        bash "$ROOT_DIR/bin/launch.sh"
    fi
    
    # Run other automated background syncs or jobs here
    # Example: python3 "$ROOT_DIR/src/sync_engine.py"

    sleep 30
done
