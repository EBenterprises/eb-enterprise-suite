#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

ROOT="$(pwd)"
STATE_DIR="$ROOT/.autonomous-runner"
STATE_FILE="$STATE_DIR/state"
LOG_DIR="$STATE_DIR/logs"
BACKUP_DIR="$STATE_DIR/backups"
LOCK_FILE="$STATE_DIR/LOCK"
STOP_FILE="$STATE_DIR/STOP"
WAKE_FILE="$STATE_DIR/wake.lock"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$BACKUP_DIR"

exec 9>"$LOCK_FILE"

if ! flock -n 9 2>/dev/null; then
    echo "REQUEST RUNNER® AUTONOMOUS SUPERVISOR ALREADY RUNNING"
    exit 0
fi

PASS=0
FAIL=0
RETRY_LIMIT=5
SLEEP_SECONDS=10

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    printf '[%s] %s\n' "$(timestamp)" "$1" | tee -a "$LOG_DIR/supervisor.log"
}

compact() {
    printf '%s\n' "$1"
}

save_state() {
    local phase="$1"
    local status="$2"

    {
        echo "phase=$phase"
        echo "status=$status"
        echo "updated=$(timestamp)"
    } > "$STATE_FILE"
}

get_state() {
    if [ -f "$STATE_FILE" ]; then
        sed -n 's/^phase=//p' "$STATE_FILE" | head -n 1
    else
        echo "0"
    fi
}

get_status() {
    if [ -f "$STATE_FILE" ]; then
        sed -n 's/^status=//p' "$STATE_FILE" | head -n 1
    else
        echo "NEW"
    fi
}

production_green() {
    if [ ! -x ./FINAL_PRODUCTION_SNAPSHOT.sh ]; then
        return 1
    fi

    ./FINAL_PRODUCTION_SNAPSHOT.sh \
        > "$LOG_DIR/baseline-$(date +%Y%m%d-%H%M%S).log" \
        2>&1
}

create_backup() {
    local label="$1"
    local destination="$BACKUP_DIR/${label}-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$destination"

    if command -v tar >/dev/null 2>&1; then
        tar \
            --exclude='./.autonomous-runner' \
            --exclude='./node_modules' \
            -czf "$destination/project.tgz" \
            . >/dev/null 2>&1 || return 1
    else
        return 1
    fi

    echo "$destination"
}

run_script() {
    local script="$1"
    local logfile="$2"

    chmod 755 "$script" 2>/dev/null || true

    timeout 0 \
        "$script" > "$logfile" 2>&1

    return $?
}

script_status_green() {
    local logfile="$1"

    if grep -qE \
        'STATUS:[[:space:]]*GREEN|READY FOR NEXT PRODUCT SURFACE|PRODUCTION BASELINE.*GREEN|PASS:.*FAIL:[[:space:]]*0' \
        "$logfile"; then
        return 0
    fi

    return 1
}

find_repair_for() {
    local phase_script="$1"
    local base

    base="$(basename "$phase_script" .sh)"

    find . \
        -maxdepth 1 \
        -type f \
        -name 'REPAIR_*.sh' \
        -print 2>/dev/null |
    while read -r repair; do
        if grep -qi "$base" "$repair" 2>/dev/null; then
            echo "$repair"
            return 0
        fi
    done

    return 1
}

run_repair() {
    local repair="$1"
    local logfile="$2"

    log "REPAIR → $(basename "$repair")"

    if production_green; then
        compact "  ✓ GREEN baseline before repair"
    else
        compact "  ✗ GREEN baseline missing before repair"
        return 1
    fi

    if ! create_backup "pre-repair" >/dev/null; then
        compact "  ✗ Backup failed"
        return 1
    fi

    chmod 755 "$repair" 2>/dev/null || true

    "$repair" > "$logfile" 2>&1

    if [ $? -eq 0 ] && script_status_green "$logfile"; then
        compact "  ✓ Repair GREEN"
        return 0
    fi

    compact "  ✗ Repair did not reach GREEN"
    return 1
}

discover_phase_scripts() {
    find . -maxdepth 1 -type f -name '*.sh' -print |
        sed 's#^\./##' |
        grep -E \
        '^(NEXT_PHASE|PHASE[0-9]|STEP[0-9]|PRODUCT|INTEGRATION|FINAL|VERIFY)' |
        grep -v '^AUTONOMOUS_REQUEST_RUNNER\.sh$' |
        sort -V
}

run_phase() {
    local phase="$1"
    local logfile="$LOG_DIR/$(basename "$phase" .sh)-$(date +%Y%m%d-%H%M%S).log"
    local attempt=1
    local repair=""

    echo
    compact "=============================================================="
    compact "PHASE: $(basename "$phase")"
    compact "=============================================================="

    while [ "$attempt" -le "$RETRY_LIMIT" ]; do

        if [ -f "$STOP_FILE" ]; then
            log "STOP FILE DETECTED"
            return 2
        fi

        compact "  Attempt $attempt/$RETRY_LIMIT"

        if ! production_green; then
            compact "  ✗ Production baseline is RED"
            save_state "$phase" "BASELINE_RED"
            return 1
        fi

        compact "  ✓ Baseline GREEN"

        chmod 755 "$phase" 2>/dev/null || true

        "$phase" > "$logfile" 2>&1
        local result=$?

        if [ "$result" -eq 0 ] && script_status_green "$logfile"; then
            compact "  ✓ $(basename "$phase") GREEN"
            save_state "$phase" "GREEN"
            PASS=$((PASS+1))
            return 0
        fi

        compact "  ✗ $(basename "$phase") failed"

        repair="$(find_repair_for "$phase" 2>/dev/null || true)"

        if [ -n "$repair" ] && [ -f "$repair" ]; then
            if run_repair \
                "$repair" \
                "$LOG_DIR/repair-$(date +%Y%m%d-%H%M%S).log"; then

                compact "  ✓ Repair completed"
                attempt=$((attempt+1))
                continue
            fi
        fi

        attempt=$((attempt+1))

        if [ "$attempt" -le "$RETRY_LIMIT" ]; then
            compact "  Waiting ${SLEEP_SECONDS}s before retry"
            sleep "$SLEEP_SECONDS"
        fi
    done

    save_state "$phase" "FAILED"
    FAIL=$((FAIL+1))

    compact "  ✗ UNRESOLVED: $(basename "$phase")"
    return 1
}

cleanup() {
    rm -f "$WAKE_FILE"
}

trap cleanup EXIT

echo "=============================================================="
echo " REQUEST RUNNER® — AUTONOMOUS BUILD SUPERVISOR"
echo "=============================================================="
echo
echo "Mode: CONTINUOUS"
echo "Checkpointing: ENABLED"
echo "Backups: ENABLED"
echo "Baseline protection: ENABLED"
echo "Automatic repair discovery: ENABLED"
echo "Automatic retry: ENABLED"
echo

touch "$WAKE_FILE"

if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock >/dev/null 2>&1 || true
fi

CURRENT="$(get_state)"
CURRENT_STATUS="$(get_status)"

log "AUTONOMOUS SUPERVISOR STARTED"
log "CHECKPOINT: $CURRENT"
log "STATUS: $CURRENT_STATUS"

if [ "$CURRENT_STATUS" = "COMPLETE" ]; then
    compact "REQUEST RUNNER® ALREADY COMPLETE"
    exit 0
fi

if ! production_green; then
    compact "✗ INITIAL PRODUCTION BASELINE IS NOT GREEN"
    compact "STOP — NO AUTONOMOUS MUTATION PERMITTED"
    save_state "$CURRENT" "BASELINE_RED"
    exit 1
fi

compact "✓ INITIAL PRODUCTION BASELINE GREEN"

mapfile -t PHASES < <(discover_phase_scripts)

if [ "${#PHASES[@]}" -eq 0 ]; then
    compact "No phase scripts discovered."
    compact "Nothing to execute."
    exit 1
fi

compact "Discovered ${#PHASES[@]} phase scripts."

START_INDEX=0

if [ "$CURRENT" != "0" ]; then
    for i in "${!PHASES[@]}"; do
        if [ "${PHASES[$i]}" = "$CURRENT" ]; then
            START_INDEX=$((i+1))
            break
        fi
    done
fi

for ((i=START_INDEX; i<${#PHASES[@]}; i++)); do

    if [ -f "$STOP_FILE" ]; then
        log "STOP FILE DETECTED — CLEAN EXIT"
        save_state "${PHASES[$i]}" "STOPPED"
        exit 0
    fi

    PHASE="${PHASES[$i]}"

    if run_phase "$PHASE"; then
        continue
    fi

    compact
    compact "=============================================================="
    compact "AUTONOMOUS SUPERVISOR PAUSED"
    compact "=============================================================="
    compact
    compact "Unresolved phase:"
    compact "  $PHASE"
    compact
    compact "The project was NOT advanced past the unresolved phase."
    compact "Checkpoint preserved."
    compact "Production baseline protection remains active."
    compact

    exit 1
done

echo
echo "=============================================================="
echo " REQUEST RUNNER® — AUTONOMOUS BUILD COMPLETE"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo
echo "FINAL PRODUCTION BASELINE:"
echo "--------------------------------------------------------------"

if production_green; then
    echo "STATUS: GREEN"
    echo
    echo "ALL DISCOVERED PHASES COMPLETED"
    save_state "COMPLETE" "COMPLETE"
else
    echo "STATUS: RED"
    save_state "FINAL_PRODUCTION_SNAPSHOT.sh" "FINAL_BASELINE_RED"
    exit 1
fi

if command -v termux-wake-unlock >/dev/null 2>&1; then
    termux-wake-unlock >/dev/null 2>&1 || true
fi

echo
echo "Logs:"
echo "  $LOG_DIR"
echo
echo "Checkpoint:"
echo "  $STATE_FILE"
echo
echo "=============================================================="
