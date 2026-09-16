#!/usr/bin/env bash
# ==============================================================================
# Executive Spectrum - Inter-Process Event Bus & Message Dispatcher
# EB Enterprises | Automated Terminal Environment
# ==============================================================================

EVENT_PIPE="${HOME}/.workspace_event_pipe"
LOG_FILE="${HOME}/.workspace_daemon.log"

init_event_bus() {
    if [[ ! -p "$EVENT_PIPE" ]]; then
        mkfifo "$EVENT_PIPE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BUS] Initialized named pipe event bus at $EVENT_PIPE." >> "$LOG_FILE"
    fi
}

publish_event() {
    local event_type="$1"
    local event_payload="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ -p "$EVENT_PIPE" ]]; then
        echo "{\"timestamp\": \"$timestamp\", \"type\": \"$event_type\", \"payload\": \"$event_payload\"}" > "$EVENT_PIPE" &
    fi
}

listen_events() {
    init_event_bus
    while true; do
        if read -r event_msg < "$EVENT_PIPE"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BUS] Dispatched Event: $event_msg" >> "$LOG_FILE"
        fi
    done
}

init_event_bus
