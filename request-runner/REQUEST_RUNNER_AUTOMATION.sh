#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

RUNTIME="$ROOT/.eb-runtime"
LOG="$RUNTIME/automation.log"
REPORT="$RUNTIME/automation-report.txt"
BACKUP="$ROOT/.platform-backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$RUNTIME" "$RUNTIME/logs"

PASS=0
FAIL=0
WARN=0

ok()   { echo "✓ $*" | tee -a "$REPORT"; PASS=$((PASS+1)); }
fail() { echo "✗ $*" | tee -a "$REPORT"; FAIL=$((FAIL+1)); }
warn() { echo "⚠ $*" | tee -a "$REPORT"; WARN=$((WARN+1)); }

run() {
    "$@" >>"$LOG" 2>&1
}

section() {
    echo
    echo "=============================================================="
    echo " $*"
    echo "=============================================================="
}

http_code() {
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "$1" 2>/dev/null || true
}

process_alive() {
    [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null
}

inspect() {
    section "1. INSPECTION — NO MODIFICATIONS"

    echo "Root: $ROOT" | tee -a "$REPORT"
    echo "Time: $(date)" | tee -a "$REPORT"

    echo
    echo "[Files]"
    for f in \
        package.json \
        server.js \
        next.config.js \
        EB_PLATFORM.sh \
        start.sh \
        launch.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        STEPS35_40_PRODUCT_VERIFICATION.sh
    do
        [ -f "$ROOT/$f" ] && ok "$f exists" || warn "$f missing"
    done

    echo
    echo "[Ports]"
    for port in 3000 3001; do
        if command -v ss >/dev/null 2>&1; then
            if ss -ltn 2>/dev/null | grep -q ":$port "; then
                ok "Port $port has listener"
            else
                warn "Port $port has no listener"
            fi
        else
            warn "ss unavailable; skipped port $port listener inspection"
        fi
    done

    echo
    echo "[Processes]"
    pgrep -af 'node|next|realtime' 2>/dev/null | head -30 || true

    echo
    echo "[PID files]"
    for f in "$RUNTIME"/*.pid; do
        [ -f "$f" ] || continue

        pid="$(cat "$f" 2>/dev/null || true)"

        if process_alive "$pid"; then
            ok "$(basename "$f") → PID $pid alive"
        else
            warn "$(basename "$f") → stale PID $pid"
        fi
    done

    echo
    echo "[HTTP]"
    for url in \
        "http://127.0.0.1:3000/request" \
        "http://127.0.0.1:3000/ops" \
        "http://127.0.0.1:3000/api/health" \
        "http://127.0.0.1:3001/health"
    do
        code="$(http_code "$url")"
        echo "$code  $url" | tee -a "$REPORT"
    done

    echo
    echo "[Socket.IO]"
    socket="$(
        curl -sS \
            --max-time 5 \
            'http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling' \
            2>/dev/null || true
    )"

    if echo "$socket" | grep -q '"sid"'; then
        ok "Socket.IO handshake"
    else
        warn "Socket.IO handshake unavailable"
    fi

    echo
    echo "[Recent logs]"
    for f in \
        "$RUNTIME/logs/next.log" \
        "$RUNTIME/logs/realtime.log"
    do
        if [ -f "$f" ]; then
            echo "--- $(basename "$f") ---"
            tail -20 "$f" | tee -a "$REPORT"
        fi
    done
}

backup() {
    section "2. SAFETY BACKUP"

    mkdir -p "$BACKUP"

    cp -a \
        EB_PLATFORM.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        STEPS35_40_PRODUCT_VERIFICATION.sh \
        package.json \
        server.js \
        next.config.js \
        start.sh \
        launch.sh \
        "$BACKUP/" 2>/dev/null || true

    if [ -d "$BACKUP" ]; then
        ok "Safety backup created"
        echo "Backup: $BACKUP" | tee -a "$REPORT"
    else
        fail "Backup creation failed"
        return 1
    fi
}

syntax_check() {
    section "3. SYNTAX VALIDATION"

    local bad=0

    for f in \
        EB_PLATFORM.sh \
        start.sh \
        launch.sh \
        REQUEST_RUNNER_RELEASE_GATE.sh \
        STEPS35_40_PRODUCT_VERIFICATION.sh
    do
        if [ -f "$f" ] && bash -n "$f"; then
            ok "$f syntax"
        else
            fail "$f syntax"
            bad=1
        fi
    done

    return "$bad"
}

repair_stale_pid() {
    section "4. SAFE RUNTIME REPAIR"

    for f in "$RUNTIME"/*.pid; do
        [ -f "$f" ] || continue

        pid="$(cat "$f" 2>/dev/null || true)"

        if ! process_alive "$pid"; then
            rm -f "$f"
            ok "Removed stale PID file $(basename "$f")"
        fi
    done
}

start_platform() {
    section "5. START EXISTING PLATFORM"

    if [ ! -x "$ROOT/EB_PLATFORM.sh" ]; then
        fail "EB_PLATFORM.sh is not executable"
        return 1
    fi

    if "$ROOT/EB_PLATFORM.sh" start >>"$LOG" 2>&1; then
        ok "Platform start command completed"
    else
        fail "Platform start command failed"
        tail -40 "$LOG" 2>/dev/null || true
        return 1
    fi
}

target_test() {
    section "6. TARGETED LIVE TEST"

    local request ops realtime

    request="$(http_code "http://127.0.0.1:3000/request")"
    ops="$(http_code "http://127.0.0.1:3000/ops")"
    realtime="$(http_code "http://127.0.0.1:3001/health")"

    [ "$request" = "200" ] \
        && ok "Customer /request — HTTP 200" \
        || fail "Customer /request — HTTP $request"

    [ "$ops" = "200" ] \
        && ok "Operations /ops — HTTP 200" \
        || fail "Operations /ops — HTTP $ops"

    [ "$realtime" = "200" ] \
        && ok "Realtime /health — HTTP 200" \
        || fail "Realtime /health — HTTP $realtime"

    socket="$(
        curl -sS \
            --max-time 5 \
            'http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling' \
            2>/dev/null || true
    )"

    echo "$socket" | grep -q '"sid"' \
        && ok "Socket.IO handshake" \
        || fail "Socket.IO handshake"

    [ "$request" = "200" ] &&
    [ "$ops" = "200" ] &&
    [ "$realtime" = "200" ]
}

release_gate() {
    section "7. FULL RELEASE GATE"

    if ./REQUEST_RUNNER_RELEASE_GATE.sh >>"$LOG" 2>&1; then
        ok "Release gate GREEN"
    else
        fail "Release gate RED"
        tail -60 "$LOG" 2>/dev/null || true
        return 1
    fi
}

final_report() {
    section "8. AUTOMATION RESULT"

    echo "PASS: $PASS"
    echo "FAIL: $FAIL"
    echo "WARN: $WARN"
    echo

    if [ "$FAIL" -eq 0 ]; then
        echo "STATUS: GREEN"
        echo "REQUEST RUNNER® OPERATIONAL"
        echo "Report: $REPORT"
        return 0
    fi

    echo "STATUS: RED"
    echo "AUTOMATION STOPPED SAFELY"
    echo "Report: $REPORT"
    return 1
}

main() {
    : > "$LOG"
    : > "$REPORT"

    section "REQUEST RUNNER® — AUTOMATED CONTROL PLANE"

    inspect

    # Never modify until inspection has completed.
    backup

    syntax_check || {
        fail "Syntax validation blocked automation"
        final_report
        exit 1
    }

    repair_stale_pid

    start_platform || {
        fail "Platform could not be started"
        final_report
        exit 1
    }

    target_test || {
        fail "Targeted live test failed"
        echo
        echo "Diagnostics preserved in:"
        echo "$LOG"
        final_report
        exit 1
    }

    release_gate || {
        fail "Release gate failed"
        final_report
        exit 1
    }

    final_report
}

main "$@"
