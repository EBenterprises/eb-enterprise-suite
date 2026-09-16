#!/data/data/com.termux/files/usr/bin/bash
set -u
set -o pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
AUTO="$ROOT/.autonomous"
STATE="$AUTO/state.json"
JOURNAL="$AUTO/journal.log"
MANIFEST="$AUTO/phase-manifest.txt"
CHECKPOINTS="$AUTO/checkpoints"
BACKUPS="$AUTO/backups"
FAILURES="$AUTO/failures"
REPAIRS="$AUTO/repairs"
LOCK="$AUTO/supervisor.lock"

mkdir -p \
    "$AUTO" \
    "$CHECKPOINTS" \
    "$BACKUPS" \
    "$FAILURES" \
    "$REPAIRS"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    printf '[%s] %s\n' "$(timestamp)" "$*" | tee -a "$JOURNAL"
}

write_state() {
    local phase="$1"
    local status="$2"
    local attempt="$3"
    local detail="${4:-}"

    cat > "$STATE" <<JSON
{
  "engine": "REQUEST RUNNER® AUTONOMOUS BUILD SUPERVISOR V2",
  "status": "$status",
  "phase": "$phase",
  "attempt": $attempt,
  "updatedAt": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "detail": "$(printf '%s' "$detail" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}
JSON
}

die() {
    log "FATAL: $*"
    write_state "SUPERVISOR" "FAILED" 0 "$*"
    exit 1
}

cleanup() {
    rm -f "$LOCK"
}

trap cleanup EXIT

if [ -e "$LOCK" ]; then
    OLD_PID="$(cat "$LOCK" 2>/dev/null || true)"

    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "AUTONOMOUS SUPERVISOR ALREADY RUNNING: PID $OLD_PID"
        exit 1
    fi

    rm -f "$LOCK"
fi

echo "$$" > "$LOCK"

cd "$ROOT" || exit 1

clear

echo "=============================================================="
echo " REQUEST RUNNER® — AUTONOMOUS BUILD SUPERVISOR V2"
echo "=============================================================="
echo
echo "Persistent execution: ENABLED"
echo "Checkpointing:        ENABLED"
echo "Backups:              ENABLED"
echo "Baseline protection:  ENABLED"
echo "Automatic retry:      ENABLED"
echo "Failure journal:      ENABLED"
echo "Resume after crash:   ENABLED"
echo "Dependency ordering: ENABLED"
echo "Supervisor recovery:  ENABLED"
echo "=============================================================="
echo

log "AUTONOMOUS SUPERVISOR V2 STARTED"

if [ -f "$STATE" ]; then
    log "Existing autonomous state detected"
else
    write_state "INITIALIZATION" "NEW" 0 "Starting autonomous execution"
fi

BASELINE="./FINAL_PRODUCTION_SNAPSHOT.sh"

if [ ! -x "$BASELINE" ]; then
    chmod 755 "$BASELINE" 2>/dev/null || true
fi

baseline_green() {
    "$BASELINE" >/dev/null 2>&1
}

verify_baseline() {
    if baseline_green; then
        return 0
    fi

    log "PRODUCTION BASELINE RED"
    return 1
}

if verify_baseline; then
    log "INITIAL PRODUCTION BASELINE GREEN"
else
    die "Initial production baseline is not GREEN"
fi

create_manifest() {
    if [ -f "$MANIFEST" ]; then
        return
    fi

    cat > "$MANIFEST" <<'MANIFEST_EOF'
# REQUEST RUNNER® AUTONOMOUS PHASE MANIFEST
#
# Only explicitly listed executable phase workers are allowed.
# Order is intentional.
#
# Format:
# PHASE|SCRIPT|DESCRIPTION

FOUNDATION|FINALIZE_CRUD_BUILD.sh|Finalize CRUD foundation
REQUESTS|NEXT_PHASE_REQUESTS_VERIFY.sh|Request lifecycle
QUEUE|NEXT_PHASE_QUEUE_VERIFY.sh|Request Queue®
RUNNERS|NEXT_PHASE_RUNNERS_VERIFY.sh|Runner® lifecycle
DISPATCH|REPAIR_DISPATCH_STATE_CONTRACT.sh|Dispatch State® contract
DISPATCH_INTEGRATION|NEXT_PHASE_DISPATCH_STATE_INTEGRATION_VERIFY.sh|Dispatch® State® integration
DISPATCH_RUNNER|NEXT_PHASE_DISPATCH_RUNNER_VERIFY.sh|Dispatch Runner® orchestration
API|NEXT_PHASE_API_VERIFY.sh|API surface
REALTIME|NEXT_PHASE_REALTIME_VERIFY.sh|Realtime surface
PRODUCT|NEXT_PHASE_PRODUCT_SURFACE_VERIFY.sh|Product surface
SYSTEM|NEXT_PHASE_SYSTEM_VERIFY.sh|System integration
END_TO_END|FINAL_END_TO_END_VERIFY.sh|Final end-to-end verification
PRODUCTION|FINAL_PRODUCTION_SNAPSHOT.sh|Final production verification
MANIFEST_EOF
}

create_manifest

phase_exists() {
    local phase="$1"
    grep -q "^${phase}|" "$MANIFEST" 2>/dev/null
}

phase_script() {
    local phase="$1"
    awk -F'|' -v p="$phase" '$1 == p {print $2; exit}' "$MANIFEST"
}

phase_description() {
    local phase="$1"
    awk -F'|' -v p="$phase" '$1 == p {print $3; exit}' "$MANIFEST"
}

phase_done_file() {
    echo "$CHECKPOINTS/$1.PASS"
}

phase_failed_file() {
    echo "$FAILURES/$1.FAIL"
}

phase_repair_file() {
    echo "$REPAIRS/$1.REPAIRED"
}

mark_done() {
    local phase="$1"
    date -u '+%Y-%m-%dT%H:%M:%SZ' > "$(phase_done_file "$phase")"
    rm -f "$(phase_failed_file "$phase")"
    write_state "$phase" "PASS" 0 "Verified"
}

mark_failure() {
    local phase="$1"
    local attempt="$2"
    local detail="$3"

    cat > "$(phase_failed_file "$phase")" <<FAIL
phase=$phase
attempt=$attempt
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
detail=$detail
FAIL
}

run_repair_discovery() {
    local phase="$1"
    local script="$2"

    log "ANALYZING FAILURE: $phase"

    case "$phase" in
        DISPATCH_INTEGRATION)
            if [ -x "$ROOT/REPAIR_DISPATCH_STATE_CONTRACT.sh" ]; then
                log "REPAIR DISCOVERY: Dispatch State® repair worker available"
                return 0
            fi
            ;;
    esac

    if grep -Rql "$phase" "$ROOT" \
        --include='REPAIR_*.sh' \
        --include='FIX_*.sh' \
        --exclude-dir=.git \
        --exclude-dir=.autonomous \
        2>/dev/null; then
        log "REPAIR DISCOVERY: matching repair worker detected"
        return 0
    fi

    return 1
}

run_repair() {
    local phase="$1"

    case "$phase" in
        DISPATCH_INTEGRATION)
            if [ -x "$ROOT/REPAIR_DISPATCH_STATE_CONTRACT.sh" ]; then
                log "RUNNING REPAIR: REPAIR_DISPATCH_STATE_CONTRACT.sh"

                if "$ROOT/REPAIR_DISPATCH_STATE_CONTRACT.sh" \
                    >> "$REPAIRS/$phase.log" 2>&1; then
                    date -u '+%Y-%m-%dT%H:%M:%SZ' > "$(phase_repair_file "$phase")"
                    log "REPAIR SUCCESS: $phase"
                    return 0
                fi

                log "REPAIR FAILED: $phase"
                return 1
            fi
            ;;
    esac

    return 1
}

run_phase() {
    local phase="$1"
    local script="$2"
    local description="$3"
    local max_attempts=5
    local attempt=1
    local output_file="$AUTO/current-phase.log"

    if [ -z "$script" ]; then
        log "SKIP: $phase has no worker"
        return 0
    fi

    if [ ! -f "$ROOT/$script" ]; then
        log "BLOCKED: $phase worker missing: $script"
        write_state "$phase" "BLOCKED" 0 "Worker missing: $script"
        return 2
    fi

    chmod 755 "$ROOT/$script" 2>/dev/null || true

    echo
    echo "=============================================================="
    echo "PHASE: $phase"
    echo "WORKER: $script"
    echo "DESCRIPTION: $description"
    echo "=============================================================="

    while [ "$attempt" -le "$max_attempts" ]; do
        write_state "$phase" "RUNNING" "$attempt" "$description"

        log "PHASE $phase — ATTEMPT $attempt/$max_attempts"

        if ! verify_baseline; then
            log "BASELINE RED BEFORE PHASE: $phase"
            return 2
        fi

        rm -f "$output_file"

        if "$ROOT/$script" > "$output_file" 2>&1; then
            if verify_baseline; then
                log "PASS: $phase"
                mark_done "$phase"
                return 0
            fi

            log "PHASE REPORTED SUCCESS BUT BASELINE IS RED"
        else
            log "PHASE FAILED: $phase"
        fi

        cp "$output_file" \
            "$FAILURES/${phase}.attempt-${attempt}.log" \
            2>/dev/null || true

        mark_failure \
            "$phase" \
            "$attempt" \
            "Worker failed or post-phase baseline failed"

        if run_repair_discovery "$phase" "$script"; then
            if run_repair "$phase"; then
                log "RETRYING $phase AFTER REPAIR"
                attempt=$((attempt+1))
                continue
            fi
        fi

        if ! verify_baseline; then
            log "BASELINE RED AFTER FAILURE — STOPPING"
            return 2
        fi

        if [ "$attempt" -lt "$max_attempts" ]; then
            log "RETRYING $phase IN 10 SECONDS"
            sleep 10
        fi

        attempt=$((attempt+1))
    done

    log "UNRESOLVED PHASE: $phase"
    write_state "$phase" "BLOCKED" "$max_attempts" "Unresolved after retries"

    return 2
}

# Build ordered phase list from the manifest.
mapfile -t PHASE_LINES < <(
    grep -v '^[[:space:]]*#' "$MANIFEST" |
    grep -E '^[A-Z0-9_]+\|[^|]+\|'
)

TOTAL="${#PHASE_LINES[@]}"
INDEX=0

log "DISCOVERED $TOTAL DECLARED PHASES"

for line in "${PHASE_LINES[@]}"; do
    IFS='|' read -r PHASE SCRIPT DESCRIPTION <<< "$line"

    [ -z "$PHASE" ] && continue

    INDEX=$((INDEX+1))

    if [ -f "$(phase_done_file "$PHASE")" ]; then
        log "CHECKPOINT $INDEX/$TOTAL: $PHASE ALREADY VERIFIED"
        continue
    fi

    echo
    log "CHECKPOINT $INDEX/$TOTAL — BEGIN $PHASE"

    while true; do
        if run_phase "$PHASE" "$SCRIPT" "$DESCRIPTION"; then
            break
        fi

        RESULT=$?

        if [ "$RESULT" -eq 2 ]; then
            log "PHASE $PHASE BLOCKED"

            if verify_baseline; then
                log "BASELINE STILL GREEN"
            else
                log "BASELINE RED — SUPERVISOR ENTERING SAFE HOLD"
            fi

            write_state "$PHASE" "BLOCKED" 0 "Waiting for repair capability"

            echo
            echo "=============================================================="
            echo " AUTONOMOUS SUPERVISOR SAFE HOLD"
            echo "=============================================================="
            echo "Phase: $PHASE"
            echo "Status: BLOCKED"
            echo "The supervisor will not corrupt the GREEN baseline."
            echo "=============================================================="

            exit 2
        fi

        sleep 5
    done

    if ! verify_baseline; then
        die "Production baseline failed after verified phase: $PHASE"
    fi

    log "CHECKPOINT SAVED: $PHASE"
done

echo
echo "=============================================================="
echo " FINAL AUTONOMOUS VERIFICATION"
echo "=============================================================="

write_state "FINAL_VERIFICATION" "RUNNING" 0 "Running final production verification"

if verify_baseline; then
    log "FINAL PRODUCTION BASELINE GREEN"
else
    die "Final production baseline failed"
fi

FINAL_TESTS=(
    "node --check apps/request-runner/dispatch-state.js"
    "node --check apps/request-runner/dispatch.js"
    "node --check apps/request-runner/dispatch-runner.js"
)

for test_command in "${FINAL_TESTS[@]}"; do
    log "FINAL CHECK: $test_command"

    if ! bash -c "$test_command" >/dev/null 2>&1; then
        die "Final verification failed: $test_command"
    fi
done

write_state "COMPLETE" "DONE" 0 "All declared phases verified"

touch "$AUTO/COMPLETE"

echo
echo "=============================================================="
echo " REQUEST RUNNER® — AUTONOMOUS BUILD COMPLETE"
echo "=============================================================="
echo
echo "STATUS: DONE"
echo "PHASES: $TOTAL"
echo "CHECKPOINTS: $CHECKPOINTS"
echo "JOURNAL: $JOURNAL"
echo "STATE: $STATE"
echo
echo "ALL DECLARED PHASES VERIFIED."
echo "PRODUCTION BASELINE GREEN."
echo "=============================================================="
