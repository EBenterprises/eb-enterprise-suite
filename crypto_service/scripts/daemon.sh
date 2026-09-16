#!/usr/bin/env bash
PID_FILE="crypto_service.pid"
LOG_FILE="crypto_service.log"
BINARY="target/release/crypto_service"

case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Service is already running (PID $(cat "$PID_FILE"))."
            exit 1
        fi
        echo "Starting crypto service daemon..."
        nohup "$BINARY" > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo "Service started with PID $(cat "$PID_FILE")."
        ;;
    stop)
        if [ ! -f "$PID_FILE" ] || ! kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Service is not running."
            rm -f "$PID_FILE"
            exit 1
        fi
        PID=$(cat "$PID_FILE")
        echo "Stopping crypto service daemon (PID $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo "Service stopped."
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Service is running (PID $(cat "$PID_FILE"))."
        else
            echo "Service is stopped."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
