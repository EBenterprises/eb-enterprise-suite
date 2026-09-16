#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — PRODUCTION CONVERGENCE REPAIR"
echo "=============================================================="
echo

LOCK="$ROOT/.completion-engine.lock"
STATE="$ROOT/.completion-engine-state"
LOGDIR="$ROOT/.completion-logs"

mkdir -p "$LOGDIR"

###############################################################################
# 1. STOP DUPLICATE COMPLETION / RELEASE-GATE / MASS-COMPLETE CHAINS
###############################################################################

echo "[1/8] COLLAPSING DUPLICATE COMPLETION CHAINS"

pkill -f "$ROOT/MASS_COMPLETE_REQUEST_RUNNER.sh" 2>/dev/null || true
pkill -f "$ROOT/REQUEST_RUNNER_RELEASE_GATE.sh" 2>/dev/null || true
pkill -f "$ROOT/FINAL_PRODUCTION_SNAPSHOT.sh" 2>/dev/null || true

sleep 2

###############################################################################
# 2. STOP ONLY ORPHANED PRODUCTION BUILDS
###############################################################################

echo "[2/8] STOPPING ORPHANED PRODUCTION BUILDS"

pkill -f "node next-build" 2>/dev/null || true
pkill -f "node npm run build" 2>/dev/null || true

sleep 2

###############################################################################
# 3. DO NOT TOUCH THE LONG-RUNNING DEV / REALTIME SERVICES
###############################################################################

echo "[3/8] PRESERVING DEVELOPMENT SERVICES"

# Intentionally preserved:
# realtime-server.js
# next dev
# next-server

###############################################################################
# 4. INSTALL SINGLETON LOCK
###############################################################################

echo "[4/8] INSTALLING SINGLETON EXECUTION LOCK"

cat > "$ROOT/COMPLETION_ENGINE_LOCK.sh" <<'LOCKEOF'
#!/data/data/com.termux/files/usr/bin/bash

ROOT="$HOME/request-runner"
LOCK="$ROOT/.completion-engine.lock"

acquire_lock() {
    if mkdir "$LOCK" 2>/dev/null; then
        echo "$$" > "$LOCK/pid"
        date +%s > "$LOCK/start"
        trap release_lock EXIT INT TERM
        return 0
    fi

    if [ -f "$LOCK/pid" ]; then
        OLD_PID="$(cat "$LOCK/pid" 2>/dev/null || true)"

        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            echo
            echo "COMPLETION ENGINE® already running: PID $OLD_PID"
            echo "Refusing duplicate execution."
            return 1
        fi
    fi

    rm -rf "$LOCK"
    mkdir "$LOCK" || return 1
    echo "$$" > "$LOCK/pid"
    date +%s > "$LOCK/start"

    trap release_lock EXIT INT TERM
    return 0
}

release_lock() {
    rm -rf "$LOCK" 2>/dev/null || true
}

acquire_lock
LOCKEOF

chmod +x "$ROOT/COMPLETION_ENGINE_LOCK.sh"

###############################################################################
# 5. CREATE HARD TIMEOUT WRAPPER
###############################################################################

echo "[5/8] INSTALLING HARD VERIFICATION TIMEOUT"

cat > "$ROOT/RUN_WITH_TIMEOUT.sh" <<'TIMEEOF'
#!/data/data/com.termux/files/usr/bin/bash

set -u

SECONDS_LIMIT="${1:-900}"
shift || true

if [ "$#" -eq 0 ]; then
    echo "RUN_WITH_TIMEOUT®: missing command"
    exit 2
fi

"$@" &
CHILD=$!

START="$(date +%s)"

while kill -0 "$CHILD" 2>/dev/null; do
    NOW="$(date +%s)"
    ELAPSED=$((NOW - START))

    if [ "$ELAPSED" -ge "$SECONDS_LIMIT" ]; then
        echo
        echo "TIMEOUT: command exceeded ${SECONDS_LIMIT}s"
        echo "PID: $CHILD"

        kill -TERM "$CHILD" 2>/dev/null || true
        sleep 3
        kill -KILL "$CHILD" 2>/dev/null || true

        wait "$CHILD" 2>/dev/null || true
        exit 124
    fi

    sleep 2
done

wait "$CHILD"
exit $?
TIMEEOF

chmod +x "$ROOT/RUN_WITH_TIMEOUT.sh"

###############################################################################
# 6. REPLACE COMPLETION ENGINE WITH CONVERGENT EXECUTION MODEL
###############################################################################

echo "[6/8] HARDENING COMPLETION ENGINE®"

cp "$ROOT/COMPLETION_ENGINE.sh" \
   "$ROOT/COMPLETION_ENGINE.sh.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

cat > "$ROOT/COMPLETION_ENGINE.sh" <<'ENGINEEOF'
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
ENGINEEOF

chmod +x "$ROOT/COMPLETION_ENGINE.sh"

###############################################################################
# 7. CREATE STATUS COMMAND
###############################################################################

echo "[7/8] INSTALLING STATUS INSPECTOR"

cat > "$ROOT/COMPLETION_STATUS.sh" <<'STATUSEOF'
#!/data/data/com.termux/files/usr/bin/bash

ROOT="$HOME/request-runner"

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — LIVE STATUS"
echo "=============================================================="
echo

if [ -f "$ROOT/.completion-engine-state" ]; then
    cat "$ROOT/.completion-engine-state"
else
    echo "status=IDLE"
fi

echo
echo "--------------------------------------------------------------"
echo " ACTIVE COMPLETION PROCESSES"
echo "--------------------------------------------------------------"

ps -ef | grep -E \
'COMPLETION_ENGINE|MASS_COMPLETE|REQUEST_RUNNER_RELEASE_GATE|FINAL_PRODUCTION_SNAPSHOT|next-build|npm run build' |
grep -v grep || true

echo
echo "--------------------------------------------------------------"
echo " DEVELOPMENT SERVICES"
echo "--------------------------------------------------------------"

ps -ef | grep -E \
'realtime-server.js|next dev|next-server' |
grep -v grep || true

echo
echo "--------------------------------------------------------------"
echo " RECENT COMPLETION LOGS"
echo "--------------------------------------------------------------"

ls -1t "$ROOT/.completion-logs" 2>/dev/null | head -5 || true

echo
echo "=============================================================="
STATUSEOF

chmod +x "$ROOT/COMPLETION_STATUS.sh"

###############################################################################
# 8. FINAL PROCESS AUDIT
###############################################################################

echo "[8/8] FINAL PROCESS AUDIT"

sleep 2

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — CONVERGENCE REPAIR COMPLETE"
echo "=============================================================="
echo

echo "Production completion is now protected by:"
echo
echo "  ✓ singleton execution lock"
echo "  ✓ stale-lock recovery"
echo "  ✓ one production build at a time"
echo "  ✓ 15-minute build timeout"
echo "  ✓ 5-minute verification timeout"
echo "  ✓ persistent execution state"
echo "  ✓ isolated completion logs"
echo "  ✓ duplicate runner suppression"
echo "  ✓ development/realtime services preserved"
echo

echo "STATUS:"
echo "--------------------------------------------------------------"

"$ROOT/COMPLETION_STATUS.sh"

echo
echo "=============================================================="
echo " REPAIR FINISHED — DO NOT START A SECOND RUNNER"
echo "=============================================================="
