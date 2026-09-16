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
flock 9 || {
    echo "ANCHOR® already running"
    exit 1
}

PASS=0
WARN=0
FAIL=0
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

http_code() {
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --connect-timeout 2 \
        --max-time 5 \
        "$1" 2>/dev/null || true
}

socket_ok() {
    local response
    response="$(
        curl -sS \
            --connect-timeout 2 \
            --max-time 5 \
            "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
            2>/dev/null || true
    )"

    echo "$response" | grep -q '"sid"'
}

pid_alive() {
    [ -n "${1:-}" ] &&
    kill -0 "$1" 2>/dev/null
}

listener_probe() {
    local port="$1"

    if command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
    elif command -v ss >/dev/null 2>&1; then
        ss -ltnp 2>/dev/null | grep -E ":$port([[:space:]]|$)" || true
    elif command -v netstat >/dev/null 2>&1; then
        netstat -ltnp 2>/dev/null | grep -E ":$port([[:space:]]|$)" || true
    fi
}

checkpoint() {
    local stamp dir
    stamp="$(date '+%Y%m%d-%H%M%S')"
    dir="$SNAP/$stamp"

    mkdir -p "$dir"

    for f in \
        ANCHOR_SELF_HEAL.sh \
        ANCHOR_UPGRADE_V2.sh \
        EB_PLATFORM.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        STEPS35_40_PRODUCT_VERIFICATION.sh \
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

inspect_runtime() {
    echo
    echo "=============================================================="
    echo " ANCHOR® v2 — INSPECTION"
    echo "=============================================================="

    echo
    echo "[1] ENVIRONMENT"
    echo "--------------------------------------------------------------"

    command -v node >/dev/null 2>&1 \
        && ok "Node $(node --version)" \
        || fail "Node missing"

    command -v npm >/dev/null 2>&1 \
        && ok "npm available" \
        || fail "npm missing"

    command -v curl >/dev/null 2>&1 \
        && ok "curl available" \
        || fail "curl missing"

    echo
    echo "[2] PROCESS EVIDENCE"
    echo "--------------------------------------------------------------"

    ps -A 2>/dev/null |
        grep -E 'next-server|next dev|realtime-server' |
        grep -v grep |
        head -n 10 || true

    echo
    echo "[3] NETWORK EVIDENCE"
    echo "--------------------------------------------------------------"

    for port in 3000 3001; do
        result="$(listener_probe "$port")"

        if [ -n "$result" ]; then
            ok "Port $port listener detected"
        else
            warn "Port $port listener not visible to OS probe"
        fi
    done

    echo
    echo "[4] APPLICATION EVIDENCE"
    echo "--------------------------------------------------------------"

    local customer operations api realtime

    customer="$(http_code "http://127.0.0.1:3000/request")"
    operations="$(http_code "http://127.0.0.1:3000/ops")"
    api="$(http_code "http://127.0.0.1:3000/api/health")"
    realtime="$(http_code "http://127.0.0.1:3001/health")"

    case "$customer" in
        2*|3*) ok "Customer /request — HTTP $customer" ;;
        *) fail "Customer /request — HTTP ${customer:-000}" ;;
    esac

    case "$operations" in
        2*|3*) ok "Operations /ops — HTTP $operations" ;;
        *) fail "Operations /ops — HTTP ${operations:-000}" ;;
    esac

    case "$api" in
        2*|3*) ok "API /health — HTTP $api" ;;
        *) fail "API /health — HTTP ${api:-000}" ;;
    esac

    case "$realtime" in
        2*|3*) ok "Realtime /health — HTTP $realtime" ;;
        *) fail "Realtime /health — HTTP ${realtime:-000}" ;;
    esac

    echo
    echo "[5] REALTIME PROTOCOL"
    echo "--------------------------------------------------------------"

    if socket_ok; then
        ok "Socket.IO Engine.IO handshake"
    else
        fail "Socket.IO Engine.IO handshake"
    fi

    echo
    echo "[6] PID FILE CONSISTENCY"
    echo "--------------------------------------------------------------"

    for f in \
        "$ROOT/.eb-runtime/next.pid" \
        "$ROOT/.eb-runtime/realtime.pid"
    do
        if [ ! -f "$f" ]; then
            warn "$(basename "$f") missing"
            continue
        fi

        pid="$(cat "$f" 2>/dev/null || true)"

        if pid_alive "$pid"; then
            ok "$(basename "$f") → live PID $pid"
        else
            warn "$(basename "$f") → stale PID $pid"
        fi
    done

    echo
    echo "[7] HISTORICAL LOG ANALYSIS"
    echo "--------------------------------------------------------------"

    if [ -f "$ROOT/.eb-runtime/logs/next.log" ] &&
       grep -q "EADDRINUSE" "$ROOT/.eb-runtime/logs/next.log"
    then
        if [ "$customer" != "000" ] || [ "$operations" != "000" ]; then
            ok "Historical EADDRINUSE detected — runtime currently serving"
        else
            warn "EADDRINUSE may correspond to a current runtime failure"
        fi
    else
        ok "No EADDRINUSE signature"
    fi
}

repair_safe_state() {
    echo
    echo "=============================================================="
    echo " ANCHOR® v2 — SAFE REPAIR"
    echo "=============================================================="

    echo
    echo "[1] STALE PID REPAIR"
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

    echo
    echo "[2] EXECUTABLE STATE"
    echo "--------------------------------------------------------------"

    for f in \
        EB_PLATFORM.sh \
        start.sh \
        launch.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        STEPS35_40_PRODUCT_VERIFICATION.sh
    do
        if [ -f "$f" ] && [ ! -x "$f" ]; then
            chmod 700 "$f"
            CHANGES=$((CHANGES+1))
            ok "Made $f executable"
        elif [ -f "$f" ]; then
            ok "$f executable"
        fi
    done

    echo
    echo "[3] SYNTAX"
    echo "--------------------------------------------------------------"

    for f in \
        EB_PLATFORM.sh \
        start.sh \
        launch.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        STEPS35_40_PRODUCT_VERIFICATION.sh
    do
        if [ -f "$f" ] && bash -n "$f"; then
            ok "$f syntax"
        elif [ -f "$f" ]; then
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

verify() {
    echo
    echo "=============================================================="
    echo " ANCHOR® v2 — FINAL VERIFICATION"
    echo "=============================================================="

    local failures=0
    local code

    for pair in \
        "Customer|http://127.0.0.1:3000/request" \
        "Operations|http://127.0.0.1:3000/ops" \
        "API|http://127.0.0.1:3000/api/health" \
        "Realtime|http://127.0.0.1:3001/health"
    do
        local name="${pair%%|*}"
        local url="${pair#*|}"

        code="$(http_code "$url")"

        case "$code" in
            2*|3*) ok "$name — HTTP $code" ;;
            *)
                fail "$name — HTTP ${code:-000}"
                failures=$((failures+1))
                ;;
        esac
    done

    if socket_ok; then
        ok "Socket.IO handshake"
    else
        fail "Socket.IO handshake"
        failures=$((failures+1))
    fi

    return "$failures"
}

run_release_gate() {
    echo
    echo "=============================================================="
    echo " ANCHOR® v2 — RELEASE GATE"
    echo "=============================================================="

    if [ -x "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh" ]; then
        "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh"
    else
        fail "Release gate missing"
        return 1
    fi
}

main() {
    clear 2>/dev/null || true

    echo "=============================================================="
    echo " ANCHOR® v2 — REQUEST RUNNER® CONTROL PLANE"
    echo " INSPECT → CHECKPOINT → SAFE REPAIR → VERIFY → RELEASE"
    echo "=============================================================="

    log "ANCHOR_V2_START"

    echo
    echo "[0] CHECKPOINT"
    echo "--------------------------------------------------------------"

    local checkpoint_dir
    checkpoint_dir="$(checkpoint)"
    ok "Checkpoint: $(basename "$checkpoint_dir")"

    # REQUIRED: inspection happens before mutation.
    inspect_runtime

    if [ "$FAIL" -gt 0 ]; then
        echo
        echo "Runtime failures detected — applying only safe repairs."
        repair_safe_state
    else
        echo
        echo "No runtime failures detected."
        repair_safe_state
    fi

    echo
    echo "[POST-REPAIR INSPECTION]"
    inspect_runtime

    echo
    echo "[FINAL VERIFICATION]"
    if verify; then
        ok "Runtime verification GREEN"
    else
        fail "Runtime verification RED"
    fi

    if [ "$FAIL" -eq 0 ]; then
        run_release_gate || true
    else
        warn "Release gate withheld because ANCHOR® detected failures"
    fi

    echo
    echo "=============================================================="
    echo " ANCHOR® v2 — RESULT"
    echo "=============================================================="
    echo "Changes: $CHANGES"
    echo "PASS:    $PASS"
    echo "WARN:    $WARN"
    echo "FAIL:    $FAIL"
    echo
    echo "Audit: $LOG"
    echo "Checkpoint: $checkpoint_dir"
    echo "=============================================================="

    log "ANCHOR_V2_END changes=$CHANGES pass=$PASS warn=$WARN fail=$FAIL"

    [ "$FAIL" -eq 0 ]
}

main "$@"
