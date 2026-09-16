#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STATE="$ROOT/.anchor"
LOG="$STATE/anchor.log"
LOCK="$STATE/lock"
SNAP="$STATE/snapshots"

mkdir -p "$STATE" "$SNAP"

exec 9>"$LOCK"
flock 9 || exit 1

PASS=0
FAIL=0
WARN=0
CHANGES=0

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
    log "PASS $1"
}

warn() {
    echo "⚠ $1"
    WARN=$((WARN+1))
    log "WARN $1"
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
    log "FAIL $1"
}

checkpoint() {
    local stamp
    stamp="$(date '+%Y%m%d-%H%M%S')"
    local dir="$SNAP/$stamp"

    mkdir -p "$dir"

    for f in \
        EB_PLATFORM.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        start.sh \
        launch.sh \
        package.json \
        server.js \
        next.config.js
    do
        [ -f "$f" ] && cp -p "$f" "$dir/$f"
    done

    echo "$dir"
}

port_pids() {
    local port="$1"

    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
    elif command -v ss >/dev/null 2>&1; then
        ss -ltnp 2>/dev/null | grep -E ":$port([[:space:]]|$)" || true
    elif command -v netstat >/dev/null 2>&1; then
        netstat -ltnp 2>/dev/null | grep -E ":$port([[:space:]]|$)" || true
    fi
}

http_code() {
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "$1" 2>/dev/null || true
}

pid_alive() {
    [ -n "${1:-}" ] &&
    kill -0 "$1" 2>/dev/null
}

inspect() {
    echo
    echo "=============================================================="
    echo " ANCHOR® — PRE-MUTATION INSPECTION"
    echo "=============================================================="

    echo
    echo "[1] ENVIRONMENT"
    echo "--------------------------------------------------------------"

    ok "Root: $ROOT"
    ok "Shell: ${SHELL:-unknown}"

    if command -v node >/dev/null 2>&1; then
        ok "Node $(node --version)"
    else
        fail "Node missing"
    fi

    if command -v npm >/dev/null 2>&1; then
        ok "npm available"
    else
        fail "npm missing"
    fi

    if command -v curl >/dev/null 2>&1; then
        ok "curl available"
    else
        fail "curl missing"
    fi

    echo
    echo "[2] PID FILES"
    echo "--------------------------------------------------------------"

    for f in \
        "$ROOT/.eb-runtime/next.pid" \
        "$ROOT/.eb-runtime/realtime.pid"
    do
        if [ -f "$f" ]; then
            pid="$(cat "$f" 2>/dev/null || true)"

            if pid_alive "$pid"; then
                ok "$(basename "$f") → live PID $pid"
                ps -p "$pid" -o pid,ppid,stat,cmd 2>/dev/null | tail -n +2 || true
            else
                warn "$(basename "$f") → stale PID $pid"
            fi
        else
            warn "$(basename "$f") → missing"
        fi
    done

    echo
    echo "[3] ACTUAL LISTENERS"
    echo "--------------------------------------------------------------"

    for port in 3000 3001; do
        result="$(port_pids "$port")"

        if [ -n "$result" ]; then
            ok "Port $port has listener"
            echo "$result" | head -n 5
        else
            warn "Port $port has no detected listener"
        fi
    done

    echo
    echo "[4] HTTP SURFACES"
    echo "--------------------------------------------------------------"

    for pair in \
        "Customer|http://127.0.0.1:3000/request" \
        "Operations|http://127.0.0.1:3000/ops" \
        "API|http://127.0.0.1:3000/api/health" \
        "Realtime|http://127.0.0.1:3001/health"
    do
        name="${pair%%|*}"
        url="${pair#*|}"
        code="$(http_code "$url")"

        case "$code" in
            2*|3*) ok "$name → HTTP $code" ;;
            *) warn "$name → HTTP ${code:-000}" ;;
        esac
    done

    echo
    echo "[5] SOCKET.IO"
    echo "--------------------------------------------------------------"

    socket="$(
        curl -sS \
            --max-time 5 \
            "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
            2>/dev/null || true
    )"

    if echo "$socket" | grep -q '"sid"'; then
        ok "Socket.IO Engine.IO handshake"
    else
        warn "Socket.IO handshake unavailable"
    fi

    echo
    echo "[6] NEXT LOG"
    echo "--------------------------------------------------------------"

    if [ -f "$ROOT/.eb-runtime/logs/next.log" ]; then
        if grep -q "EADDRINUSE" "$ROOT/.eb-runtime/logs/next.log"; then
            warn "Previous Next.js EADDRINUSE detected"
        else
            ok "No EADDRINUSE signature in recent Next log"
        fi

        tail -n 8 "$ROOT/.eb-runtime/logs/next.log" 2>/dev/null || true
    fi

    echo
    echo "[7] SYNTAX"
    echo "--------------------------------------------------------------"

    for f in \
        EB_PLATFORM.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        start.sh \
        launch.sh
    do
        if [ -f "$f" ] && bash -n "$f"; then
            ok "$f syntax"
        else
            fail "$f syntax"
        fi
    done

    for f in \
        server.js \
        framework/index.js
    do
        if [ -f "$f" ] && node --check "$f" >/dev/null 2>&1; then
            ok "$f syntax"
        elif [ -f "$f" ]; then
            fail "$f syntax"
        fi
    done
}

repair_stale_pids() {
    echo
    echo "[REPAIR 1] STALE RUNTIME STATE"
    echo "--------------------------------------------------------------"

    for f in \
        "$ROOT/.eb-runtime/next.pid" \
        "$ROOT/.eb-runtime/realtime.pid"
    do
        if [ -f "$f" ]; then
            pid="$(cat "$f" 2>/dev/null || true)"

            if ! pid_alive "$pid"; then
                rm -f "$f"
                CHANGES=$((CHANGES+1))
                ok "Removed stale $(basename "$f")"
            fi
        fi
    done
}

repair_port_conflicts() {
    echo
    echo "[REPAIR 2] PORT CONFLICT ANALYSIS"
    echo "--------------------------------------------------------------"

    for port in 3000 3001; do
        result="$(port_pids "$port")"

        if [ -n "$result" ]; then
            echo "Port $port:"
            echo "$result" | head -n 8

            warn "Port $port is already occupied"

            log "PORT_OCCUPIED port=$port"
        fi
    done
}

repair_launcher_state() {
    echo
    echo "[REPAIR 3] LAUNCHER CONSISTENCY"
    echo "--------------------------------------------------------------"

    if [ ! -x "$ROOT/EB_PLATFORM.sh" ]; then
        chmod 700 "$ROOT/EB_PLATFORM.sh"
        CHANGES=$((CHANGES+1))
        ok "EB_PLATFORM.sh executable"
    fi

    if [ ! -x "$ROOT/start.sh" ]; then
        chmod 700 "$ROOT/start.sh"
        CHANGES=$((CHANGES+1))
        ok "start.sh executable"
    fi

    if [ ! -x "$ROOT/launch.sh" ]; then
        chmod 700 "$ROOT/launch.sh"
        CHANGES=$((CHANGES+1))
        ok "launch.sh executable"
    fi
}

verify_after_repair() {
    echo
    echo "=============================================================="
    echo " ANCHOR® — POST-REPAIR VERIFICATION"
    echo "=============================================================="

    local failures=0

    for pair in \
        "Customer|http://127.0.0.1:3000/request" \
        "Operations|http://127.0.0.1:3000/ops" \
        "API|http://127.0.0.1:3000/api/health" \
        "Realtime|http://127.0.0.1:3001/health"
    do
        name="${pair%%|*}"
        url="${pair#*|}"
        code="$(http_code "$url")"

        case "$code" in
            2*|3*)
                ok "$name — HTTP $code"
                ;;
            *)
                fail "$name — HTTP ${code:-000}"
                failures=$((failures+1))
                ;;
        esac
    done

    socket="$(
        curl -sS \
            --max-time 5 \
            "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
            2>/dev/null || true
    )"

    if echo "$socket" | grep -q '"sid"'; then
        ok "Socket.IO handshake"
    else
        fail "Socket.IO handshake"
        failures=$((failures+1))
    fi

    return "$failures"
}

start_existing_platform() {
    echo
    echo "[CONTROL] PLATFORM START"
    echo "--------------------------------------------------------------"

    if [ -x "$ROOT/EB_PLATFORM.sh" ]; then
        "$ROOT/EB_PLATFORM.sh" start || true
    fi
}

release_gate() {
    echo
    echo "[CONTROL] RELEASE GATE"
    echo "--------------------------------------------------------------"

    if [ -x "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh" ]; then
        "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh"
    else
        warn "Release gate unavailable"
    fi
}

main() {
    echo
    echo "=============================================================="
    echo " ANCHOR® — REQUEST RUNNER® AUTONOMOUS CONTROL PLANE"
    echo " INSPECT → CLASSIFY → REPAIR → VERIFY → RELEASE"
    echo "=============================================================="

    log "ANCHOR START"

    checkpoint="$(checkpoint)"
    ok "Checkpoint created: $(basename "$checkpoint")"

    inspect

    repair_stale_pids
    repair_port_conflicts
    repair_launcher_state

    echo
    echo "[CONTROL] RE-INSPECTION"
    echo "--------------------------------------------------------------"

    inspect

    echo
    echo "[CONTROL] START"
    echo "--------------------------------------------------------------"

    start_existing_platform

    if verify_after_repair; then
        ok "Runtime verification passed"
    else
        warn "Runtime verification still has failures"
    fi

    release_gate || true

    echo
    echo "=============================================================="
    echo " ANCHOR® RUN COMPLETE"
    echo "=============================================================="
    echo "Changes: $CHANGES"
    echo "PASS:    $PASS"
    echo "WARN:    $WARN"
    echo "FAIL:    $FAIL"
    echo
    echo "Audit: $LOG"
    echo "Checkpoint: $checkpoint"
    echo "=============================================================="

    log "ANCHOR END changes=$CHANGES pass=$PASS warn=$WARN fail=$FAIL"
}

main "$@"
