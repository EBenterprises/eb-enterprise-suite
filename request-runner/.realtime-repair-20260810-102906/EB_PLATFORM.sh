#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PID_DIR="$ROOT/.runtime"
NEXT_PID="$PID_DIR/next.pid"
REALTIME_PID="$PID_DIR/realtime.pid"

mkdir -p "$PID_DIR"

get_lan_ip() {
    local ip=""

    if command -v ip >/dev/null 2>&1; then
        ip="$(ip -4 addr show 2>/dev/null |
            awk '/inet / && $2 !~ /^127\./ {
                split($2,a,"/");
                print a[1];
                exit
            }')"
    fi

    if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
        ip="$(ifconfig 2>/dev/null |
            awk '/inet / && $2 !~ /^127\./ {
                print $2;
                exit
            }')"
    fi

    printf '%s' "${ip:-127.0.0.1}"
}

is_running() {
    local pid_file="$1"

    [ -f "$pid_file" ] || return 1

    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"

    [ -n "$pid" ] || return 1
    kill -0 "$pid" 2>/dev/null
}

wait_for_http() {
    local url="$1"
    local attempts="${2:-30}"

    for ((i=1; i<=attempts; i++)); do
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
        return 0
    fi

    echo "[1] Starting realtime server..."

    if [ -f "$ROOT/realtime/server.js" ]; then
        nohup node "$ROOT/realtime/server.js" \
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    elif [ -f "$ROOT/server-realtime.js" ]; then
        nohup node "$ROOT/server-realtime.js" \
            > "$ROOT/.runtime/realtime.log" 2>&1 &

        echo $! > "$REALTIME_PID"
    else
        echo "⚠ No dedicated realtime server entrypoint found"
        return 0
    fi

    sleep 1

    if is_running "$REALTIME_PID"; then
        echo "✓ Realtime® started — PID $(cat "$REALTIME_PID")"
    else
        echo "⚠ Realtime® process exited; inspect .runtime/realtime.log"
    fi
}

start_next() {
    if is_running "$NEXT_PID"; then
        echo "✓ Request Runner® already running"
        return 0
    fi

    echo "[2] Starting Request Runner®..."

    if [ "${NODE_ENV:-}" = "production" ]; then
        nohup npm run start \
            > "$ROOT/.runtime/next.log" 2>&1 &
    else
        nohup npm run dev \
            > "$ROOT/.runtime/next.log" 2>&1 &
    fi

    echo $! > "$NEXT_PID"

    echo "✓ Next.js started — PID $(cat "$NEXT_PID")"
}

start_app() {
    echo
    echo "=============================================================="
    echo " EB PLATFORM® — START"
    echo " Request Runner®"
    echo "=============================================================="
    echo

    mkdir -p "$ROOT/.runtime"

    start_realtime
    start_next

    echo
    echo "[3] Waiting for application..."

    if wait_for_http "http://127.0.0.1:3000" 30; then
        echo "✓ HTTP application is responding"
    else
        echo "✗ HTTP application did not become ready"
        echo
        echo "Last application log:"
        tail -n 40 "$ROOT/.runtime/next.log" 2>/dev/null || true
        return 1
    fi

    echo
    status_app
}

stop_app() {
    echo
    echo "=============================================================="
    echo " EB PLATFORM® — STOP"
    echo "=============================================================="
    echo

    for pid_file in "$NEXT_PID" "$REALTIME_PID"; do
        if [ -f "$pid_file" ]; then
            pid="$(cat "$pid_file" 2>/dev/null || true)"

            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
                echo "✓ Stopped PID $pid"
            fi

            rm -f "$pid_file"
        fi
    done

    echo "✓ EB Platform® stopped"
}

status_app() {
    local lan_ip
    lan_ip="$(get_lan_ip)"

    echo
    echo "=============================================================="
    echo " EB PLATFORM® — STATUS"
    echo "=============================================================="

    if is_running "$NEXT_PID"; then
        echo "✓ Request Runner® : RUNNING"
    elif curl -fsS --max-time 2 http://127.0.0.1:3000 >/dev/null 2>&1; then
        echo "✓ Request Runner® : RUNNING"
    else
        echo "✗ Request Runner® : STOPPED"
    fi

    if is_running "$REALTIME_PID"; then
        echo "✓ Realtime®       : RUNNING"
    elif curl -fsS --max-time 2 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        >/dev/null 2>&1; then
        echo "✓ Realtime®       : RUNNING"
    else
        echo "⚠ Realtime®       : NOT VERIFIED"
    fi

    echo
    echo "Customer:"
    echo "  http://127.0.0.1:3000/request"

    echo
    echo "Operations:"
    echo "  http://127.0.0.1:3000/ops"

    echo
    echo "Realtime:"
    echo "  http://127.0.0.1:3001"

    echo
    echo "LAN:"
    echo "  http://${lan_ip}:3000"

    echo
    echo "=============================================================="
}

doctor() {
    cd "$ROOT"

    bash "$ROOT/bin/eb" doctor
}

tests() {
    cd "$ROOT"

    node "$ROOT/tests/run.js"
}

case "${1:-status}" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        stop_app
        sleep 1
        start_app
        ;;
    status)
        status_app
        ;;
    doctor)
        doctor
        ;;
    test|tests)
        tests
        ;;
    *)
        echo "Usage:"
        echo "  $0 start"
        echo "  $0 stop"
        echo "  $0 restart"
        echo "  $0 status"
        echo "  $0 doctor"
        echo "  $0 test"
        exit 1
        ;;
esac
