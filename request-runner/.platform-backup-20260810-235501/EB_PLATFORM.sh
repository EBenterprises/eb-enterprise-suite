#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PID_DIR="$ROOT/.runtime"
NEXT_PID="$PID_DIR/next.pid"
REALTIME_PID="$PID_DIR/realtime.pid"

mkdir -p "$PID_DIR"

is_running() {
    local file="$1"

    [ -f "$file" ] || return 1

    local pid
    pid="$(cat "$file" 2>/dev/null || true)"

    [ -n "$pid" ] || return 1

    kill -0 "$pid" 2>/dev/null
}

get_lan_ip() {
    local ip=""

    if command -v ip >/dev/null 2>&1; then
        ip="$(
            ip -4 addr show 2>/dev/null |
            awk '/inet / && $2 !~ /^127\./ {
                split($2,a,"/");
                print a[1];
                exit
            }'
        )"
    fi

    printf '%s' "${ip:-127.0.0.1}"
}

wait_http() {
    local url="$1"

    for _ in $(seq 1 30); do
        if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
            return 0
        fi

        sleep 1
    done

    return 1
}

start_realtime() {
    if is_running "$REALTIME_PID"; then
        echo "✓ Realtime® already running"
        return
    fi

    echo "[1] Starting real Socket.IO® server..."

    nohup node "$ROOT/realtime-server.js" \
        > "$ROOT/.runtime/realtime.log" 2>&1 &

    echo $! > "$REALTIME_PID"

    sleep 1

    if is_running "$REALTIME_PID"; then
        echo "✓ Realtime® running — PID $(cat "$REALTIME_PID")"
    else
        echo "✗ Realtime® failed to start"
        tail -n 100 "$ROOT/.runtime/realtime.log" 2>/dev/null || true
        return 1
    fi
}

start_next() {
    if is_running "$NEXT_PID"; then
        echo "✓ Request Runner® already running"
        return
    fi

    echo "[2] Starting Request Runner®..."

    if [ "${NODE_ENV:-development}" = "production" ]; then
        nohup npm run start \
            > "$ROOT/.runtime/next.log" 2>&1 &
    else
        nohup npm run dev \
            > "$ROOT/.runtime/next.log" 2>&1 &
    fi

    echo $! > "$NEXT_PID"

    sleep 2

    if is_running "$NEXT_PID"; then
        echo "✓ Request Runner® running — PID $(cat "$NEXT_PID")"
    else
        echo "✗ Request Runner® failed to start"
        tail -n 100 "$ROOT/.runtime/next.log" 2>/dev/null || true
        return 1
    fi
}

stop() {
    echo "Stopping EB Platform®..."

    for file in "$NEXT_PID" "$REALTIME_PID"; do
        if [ -f "$file" ]; then
            pid="$(cat "$file" 2>/dev/null || true)"

            if [ -n "$pid" ]; then
                kill "$pid" 2>/dev/null || true
            fi

            rm -f "$file"
        fi
    done

    echo "✓ Platform stopped"
}

status() {
    local lan
    lan="$(get_lan_ip)"

    echo
    echo "=============================================================="
    echo " EB PLATFORM® — STATUS"
    echo "=============================================================="

    if curl -fsS --max-time 2 \
        http://127.0.0.1:3000/api/health \
        >/dev/null 2>&1; then
        echo "✓ API®            : HEALTHY"
    else
        echo "✗ API®            : DOWN"
    fi

    if curl -fsS --max-time 2 \
        http://127.0.0.1:3000/request \
        >/dev/null 2>&1; then
        echo "✓ Customer®       : HEALTHY"
    else
        echo "✗ Customer®       : DOWN"
    fi

    if curl -fsS --max-time 2 \
        http://127.0.0.1:3000/ops \
        >/dev/null 2>&1; then
        echo "✓ Operations®     : HEALTHY"
    else
        echo "✗ Operations®     : DOWN"
    fi

    if curl -fsS --max-time 2 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        >/dev/null 2>&1; then
        echo "✓ Realtime®       : HEALTHY"
    else
        echo "✗ Realtime®       : DOWN"
    fi

    echo
    echo "Customer:"
    echo "  http://127.0.0.1:3000/request"

    echo
    echo "Operations:"
    echo "  http://127.0.0.1:3000/ops"

    echo
    echo "API:"
    echo "  http://127.0.0.1:3000/api/health"

    echo
    echo "Realtime:"
    echo "  http://127.0.0.1:3001/health"

    echo
    echo "LAN:"
    echo "  http://${lan}:3000"

    echo
    echo "=============================================================="
}

case "${1:-status}" in
    start)
        start_realtime
        start_next
        ;;

    stop)
        stop
        ;;

    restart)
        stop
        sleep 1
        start_realtime
        start_next
        ;;

    status)
        status
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
