#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

RUNTIME="$ROOT/.runtime"
mkdir -p "$RUNTIME"

NEXT_PID="$RUNTIME/next.pid"
REALTIME_PID="$RUNTIME/realtime.pid"

NEXT_LOG="$RUNTIME/next.log"
REALTIME_LOG="$RUNTIME/realtime.log"

LOCK="$RUNTIME/supervisor.lock"

exec 9>"$LOCK"
if ! flock -n 9 2>/dev/null; then
    echo "Supervisor already running."
    exit 0
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

pid_alive() {
    local file="$1"

    [ -f "$file" ] || return 1

    local pid
    pid="$(cat "$file" 2>/dev/null || true)"

    [ -n "$pid" ] || return 1
    kill -0 "$pid" 2>/dev/null
}

http_ok() {
    curl -fsS --max-time 3 "$1" >/dev/null 2>&1
}

realtime_ok() {
    curl -fsS --max-time 3 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        2>/dev/null |
        grep -q '"sid"'
}

find_realtime_entry() {
    for file in \
        "$ROOT/realtime-server.js" \
        "$ROOT/server-realtime.js" \
        "$ROOT/realtime/server.js" \
        "$ROOT/realtime/index.js"
    do
        if [ -f "$file" ]; then
            printf '%s' "$file"
            return 0
        fi
    done

    return 1
}

start_realtime() {
    local entry

    entry="$(find_realtime_entry)" || {
        log "ERROR: realtime entrypoint not found"
        return 1
    }

    log "Starting Realtime®: $entry"

    : > "$REALTIME_LOG"

    nohup node "$entry" \
        >> "$REALTIME_LOG" 2>&1 &

    echo $! > "$REALTIME_PID"

    for _ in $(seq 1 15); do
        if realtime_ok; then
            log "Realtime® healthy on port 3001"
            return 0
        fi

        sleep 1
    done

    log "ERROR: Realtime® failed to become healthy"
    tail -n 50 "$REALTIME_LOG" 2>/dev/null || true

    return 1
}

start_next() {
    log "Starting Request Runner®"

    if pid_alive "$NEXT_PID" && http_ok "http://127.0.0.1:3000"; then
        log "Request Runner® already healthy"
        return 0
    fi

    rm -f "$NEXT_PID"

    : > "$NEXT_LOG"

    nohup npm run dev \
        >> "$NEXT_LOG" 2>&1 &

    echo $! > "$NEXT_PID"

    for _ in $(seq 1 30); do
        if http_ok "http://127.0.0.1:3000/request"; then
            log "Request Runner® healthy on port 3000"
            return 0
        fi

        sleep 1
    done

    log "ERROR: Request Runner® failed to become healthy"
    tail -n 80 "$NEXT_LOG" 2>/dev/null || true

    return 1
}

check_realtime() {
    if realtime_ok; then
        return 0
    fi

    log "Realtime® unhealthy"

    if pid_alive "$REALTIME_PID"; then
        local pid
        pid="$(cat "$REALTIME_PID")"

        log "Stopping unhealthy Realtime® PID $pid"
        kill "$pid" 2>/dev/null || true
        sleep 1
    fi

    rm -f "$REALTIME_PID"

    start_realtime
}

check_next() {
    if http_ok "http://127.0.0.1:3000/request"; then
        return 0
    fi

    log "Request Runner® unhealthy"

    if pid_alive "$NEXT_PID"; then
        local pid
        pid="$(cat "$NEXT_PID")"

        log "Stopping unhealthy Request Runner® PID $pid"
        kill "$pid" 2>/dev/null || true
        sleep 1
    fi

    rm -f "$NEXT_PID"

    start_next
}

status() {
    echo
    echo "=============================================================="
    echo " EB SUPERVISOR® — STATUS"
    echo "=============================================================="
    echo

    if http_ok "http://127.0.0.1:3000/request"; then
        echo "✓ Request Runner® : HEALTHY"
    else
        echo "✗ Request Runner® : DOWN"
    fi

    if realtime_ok; then
        echo "✓ Realtime®       : HEALTHY"
    else
        echo "✗ Realtime®       : DOWN"
    fi

    echo

    if [ -f "$NEXT_PID" ]; then
        echo "Next PID:"
        cat "$NEXT_PID"
    fi

    if [ -f "$REALTIME_PID" ]; then
        echo "Realtime PID:"
        cat "$REALTIME_PID"
    fi

    echo
}

case "${1:-check}" in

    start)
        log "Supervisor starting platform"

        check_realtime
        check_next

        status
        ;;

    check)
        check_realtime
        check_next

        status
        ;;

    restart)
        log "Restarting platform"

        if pid_alive "$NEXT_PID"; then
            kill "$(cat "$NEXT_PID")" 2>/dev/null || true
        fi

        if pid_alive "$REALTIME_PID"; then
            kill "$(cat "$REALTIME_PID")" 2>/dev/null || true
        fi

        rm -f "$NEXT_PID" "$REALTIME_PID"

        sleep 2

        start_realtime
        start_next

        status
        ;;

    status)
        status
        ;;

    *)
        echo "Usage:"
        echo "  $0 start"
        echo "  $0 check"
        echo "  $0 restart"
        echo "  $0 status"
        exit 1
        ;;

esac
