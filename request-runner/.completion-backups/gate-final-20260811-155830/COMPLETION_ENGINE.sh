
# COMPLETION_ENGINE_BUILD_RUNTIME_LOADED
COMPLETION_ENGINE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$COMPLETION_ENGINE_ROOT/COMPLETION_ENGINE_BUILD_RUNTIME.sh" ]; then
    . "$COMPLETION_ENGINE_ROOT/COMPLETION_ENGINE_BUILD_RUNTIME.sh"
fi

#!/data/data/com.termux/files/usr/bin/bash

set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

LOCK="$ROOT/.completion-engine.lock"
LOGDIR="$ROOT/.completion-logs"

mkdir -p "$LOGDIR"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    printf '[%s] %s\n' "$(timestamp)" "$*"
}

phase() {
    printf '\n[%s] %s\n' "$1" "$2"
}

###############################################################################
# SINGLE INSTANCE
###############################################################################

if [ -d "$LOCK" ]; then
    if [ -f "$LOCK/pid" ]; then
        OLD_PID="$(cat "$LOCK/pid" 2>/dev/null || true)"

        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            log "Another COMPLETION ENGINE® instance is active: PID $OLD_PID"
            exit 10
        fi
    fi

    rm -rf "$LOCK"
fi

mkdir "$LOCK" || exit 11

echo "$$" > "$LOCK/pid"
timestamp="$(date +%s)"
echo "$timestamp" > "$LOCK/start"

cleanup() {
    rm -rf "$LOCK" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

###############################################################################
# STATE
###############################################################################

STATE="$ROOT/.completion-engine-state"

cat > "$STATE" <<EOF_STATE
status=RUNNING
pid=$$
started=$(date +%s)
phase=BOOT
EOF_STATE

###############################################################################
# CONTROLLED BUILD
###############################################################################

run_build() {
    local LOGFILE="$LOGDIR/build-$(date +%Y%m%d-%H%M%S).log"

    log "BUILD: npm run build"

    if [ ! -x "$ROOT/RUN_WITH_TIMEOUT.sh" ]; then
        log "ERROR: timeout wrapper missing"
        return 20
    fi

    "$ROOT/RUN_WITH_TIMEOUT.sh" 900 \
        npm run build >"$LOGFILE" 2>&1

    RC=$?

    if [ "$RC" -eq 0 ]; then
        log "BUILD: PASS"
        return 0
    fi

    if [ "$RC" -eq 124 ]; then
        log "BUILD: TIMEOUT"
        return 124
    fi

    log "BUILD: FAILED rc=$RC"
    log "LOG: $LOGFILE"

    return "$RC"
}

###############################################################################
# DISCOVERY
###############################################################################

phase "DISCOVERY" "Inspecting production surface"

cat > "$STATE" <<EOF_STATE
status=RUNNING
pid=$$
started=$timestamp
phase=DISCOVERY
EOF_STATE

if [ ! -f package.json ]; then
    log "ERROR: package.json missing"
    exit 30
fi

###############################################################################
# BUILD — EXACTLY ONCE
###############################################################################

phase "BUILD" "Running one controlled production build"

cat > "$STATE" <<EOF_STATE
status=RUNNING
pid=$$
started=$timestamp
phase=BUILD
EOF_STATE

run_build

RC=$?

if [ "$RC" -ne 0 ]; then
    cat > "$STATE" <<EOF_STATE
status=FAILED
pid=$$
started=$timestamp
phase=BUILD
exit_code=$RC
EOF_STATE

    log "PRODUCTION BUILD DID NOT CONVERGE"
    exit "$RC"
fi

###############################################################################
# VERIFICATION
###############################################################################

phase "VERIFY" "Running bounded production verification"

cat > "$STATE" <<EOF_STATE
status=RUNNING
pid=$$
started=$timestamp
phase=VERIFY
EOF_STATE

VERIFY_LOG="$LOGDIR/verification-$(date +%Y%m%d-%H%M%S).log"

VERIFY_RC=0

if [ -f "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh" ]; then
    "$ROOT/RUN_WITH_TIMEOUT.sh" 300 \
        bash "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh" \
        >"$VERIFY_LOG" 2>&1 || VERIFY_RC=$?
else
    log "Release gate not present; using build verification only."
fi

if [ "$VERIFY_RC" -eq 124 ]; then
    log "VERIFICATION TIMEOUT"
fi

if [ "$VERIFY_RC" -ne 0 ]; then
    cat > "$STATE" <<EOF_STATE
status=FAILED
pid=$$
started=$timestamp
phase=VERIFY
exit_code=$VERIFY_RC
log=$VERIFY_LOG
EOF_STATE

    log "VERIFICATION FAILED"
    log "LOG: $VERIFY_LOG"
    exit "$VERIFY_RC"
fi

###############################################################################
# COMPLETE
###############################################################################

cat > "$STATE" <<EOF_STATE
status=COMPLETE
pid=$$
started=$timestamp
completed=$(date +%s)
phase=COMPLETE
EOF_STATE

phase "COMPLETE" "Production convergence achieved"

log "COMPLETION ENGINE® COMPLETE"
exit 0
