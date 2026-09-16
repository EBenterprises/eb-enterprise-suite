#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STATE="$ROOT/.anchor"
LOG="$STATE/guardian.log"
LOCK="$STATE/guardian.lock"
INTERVAL="${ANCHOR_INTERVAL:-30}"

mkdir -p "$STATE"

exec 9>"$LOCK"
flock -n 9 || {
    echo "ANCHOR® Guardian already active"
    exit 0
}

log() {
    printf '%s %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$*" >> "$LOG"
}

healthy() {
    local customer operations api realtime socket

    customer="$(
        curl -sS -o /dev/null -w '%{http_code}' \
        --connect-timeout 2 --max-time 5 \
        http://127.0.0.1:3000/request 2>/dev/null || true
    )"

    operations="$(
        curl -sS -o /dev/null -w '%{http_code}' \
        --connect-timeout 2 --max-time 5 \
        http://127.0.0.1:3000/ops 2>/dev/null || true
    )"

    api="$(
        curl -sS -o /dev/null -w '%{http_code}' \
        --connect-timeout 2 --max-time 5 \
        http://127.0.0.1:3000/api/health 2>/dev/null || true
    )"

    realtime="$(
        curl -sS -o /dev/null -w '%{http_code}' \
        --connect-timeout 2 --max-time 5 \
        http://127.0.0.1:3001/health 2>/dev/null || true
    )"

    socket="$(
        curl -sS \
        --connect-timeout 2 --max-time 5 \
        'http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling' \
        2>/dev/null || true
    )"

    case "$customer:$operations:$api:$realtime" in
        2*:*:2*:2*) ;;
        *) return 1 ;;
    esac

    echo "$socket" | grep -q '"sid"'
}

repair() {
    log "HEALTH_FAILURE"

    echo
    echo "⚠ ANCHOR® Guardian detected unhealthy runtime"
    echo "→ invoking inspect-first recovery"

    if [ -x "$ROOT/ANCHOR_UPGRADE_V2.sh" ]; then
        "$ROOT/ANCHOR_UPGRADE_V2.sh" || true
    else
        log "ANCHOR_UPGRADE_V2_MISSING"
    fi
}

echo "=============================================================="
echo " ANCHOR® GUARDIAN"
echo " REQUEST RUNNER® AUTONOMOUS RUNTIME SUPERVISOR"
echo "=============================================================="
echo "Interval: ${INTERVAL}s"
echo "Mode: inspect → classify → repair → verify"
echo

log "GUARDIAN_START interval=$INTERVAL"

while true; do
    if healthy; then
        printf '%s ✓ HEALTHY\n' "$(date '+%H:%M:%S')"
        log "HEALTHY"
    else
        printf '%s ⚠ UNHEALTHY\n' "$(date '+%H:%M:%S')"
        repair
    fi

    sleep "$INTERVAL"
done
