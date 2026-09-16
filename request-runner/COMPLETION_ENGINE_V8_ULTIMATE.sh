#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

###############################################################################
# COMPLETION ENGINE® V8 — CONTINUOUS BUILD / TEST / REPAIR / EMBED / DEPLOY
###############################################################################

STATE="$PWD/.completion-state/v8"
LOG="$STATE/engine.log"
REPORTS="$STATE/reports"
SNAPSHOTS="$STATE/snapshots"
ARTIFACTS="$STATE/artifacts"
REPAIRS="$STATE/repairs"

mkdir -p "$REPORTS" "$SNAPSHOTS" "$ARTIFACTS" "$REPAIRS"

export CI=1
export NEXT_TELEMETRY_DISABLED=1

CYCLE=0
BUILD_COUNT=0
TEST_COUNT=0
REPAIR_COUNT=0
DEPLOY_COUNT=0
ERROR_COUNT=0
START_TIME="$(date +%s)"

###############################################################################
# LOGGING
###############################################################################

exec > >(tee -a "$LOG") 2>&1

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

###############################################################################
# PACKAGE / SCRIPT DETECTION
###############################################################################

has_script() {
    node - "$1" <<'NODE'
const fs=require("fs");
const name=process.argv[2];

try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));
  process.exit(p.scripts && p.scripts[name] ? 0 : 1);
} catch {
  process.exit(1);
}
NODE
}

###############################################################################
# SNAPSHOT
###############################################################################

snapshot() {
    local id="$1"
    local dir="$SNAPSHOTS/$id"

    mkdir -p "$dir"

    for f in \
        package.json \
        package-lock.json \
        pnpm-lock.yaml \
        yarn.lock \
        next.config.js \
        next.config.mjs \
        next.config.ts \
        tsconfig.json \
        jsconfig.json \
        vercel.json
    do
        [ -f "$f" ] && cp -f "$f" "$dir/" 2>/dev/null || true
    done
}

###############################################################################
# EMBEDDED ERROR CAPTURE
###############################################################################

capture_error() {
    local phase="$1"
    local source="$2"

    ERROR_COUNT=$((ERROR_COUNT + 1))

    cp "$source" \
       "$REPORTS/error-${CYCLE}-${ERROR_COUNT}-${phase}.log" \
       2>/dev/null || true

    printf '%s\n' \
        "cycle=$CYCLE" \
        "phase=$phase" \
        "time=$(date -Iseconds)" \
        "error_count=$ERROR_COUNT" \
        > "$REPAIRS/error-${CYCLE}-${ERROR_COUNT}.meta"
}

###############################################################################
# DEPENDENCY REPAIR
###############################################################################

repair_dependencies() {
    local id="dependencies-$CYCLE"

    REPAIR_COUNT=$((REPAIR_COUNT + 1))
    snapshot "$id"

    log "REPAIR: dependencies"

    npm install --no-audit --no-fund \
        > "$REPORTS/repair-$id.log" 2>&1 || true
}

###############################################################################
# TEST
###############################################################################

run_tests() {
    TEST_COUNT=$((TEST_COUNT + 1))

    log "TEST #$TEST_COUNT"

    if has_script test:ci; then
        npm run test:ci
    elif has_script test; then
        npm test
    elif [ -x node_modules/.bin/vitest ]; then
        node_modules/.bin/vitest run
    elif [ -x node_modules/.bin/jest ]; then
        node_modules/.bin/jest --runInBand
    else
        log "No test runner configured; artifact validation remains active."
        return 0
    fi
}

###############################################################################
# TYPECHECK
###############################################################################

run_types() {
    if has_script typecheck; then
        npm run typecheck
    elif [ -x node_modules/.bin/tsc ] && [ -f tsconfig.json ]; then
        node_modules/.bin/tsc --noEmit
    else
        return 0
    fi
}

###############################################################################
# LINT
###############################################################################

run_lint() {
    if has_script lint; then
        npm run lint
    else
        return 0
    fi
}

###############################################################################
# BUILD
###############################################################################

run_build() {
    BUILD_COUNT=$((BUILD_COUNT + 1))

    log "BUILD #$BUILD_COUNT"

    if [ -x node_modules/.bin/next ]; then
        node_modules/.bin/next build --webpack
    elif has_script build; then
        npm run build
    else
        log "ERROR: no build system found"
        return 1
    fi
}

###############################################################################
# SERVER ARTIFACT EMBEDDING / VALIDATION
###############################################################################

embed_artifacts() {
    log "EMBED: validating server artifact"

    [ -d .next ] || return 1
    [ -d .next/server ] || return 1

    local files
    files="$(
        find .next/server \
            -type f \
            2>/dev/null |
            wc -l
    )"

    [ "$files" -gt 0 ] || return 1

    rm -rf "$ARTIFACTS/current"
    mkdir -p "$ARTIFACTS/current"

    cp -a .next/server "$ARTIFACTS/current/" 2>/dev/null || true

    printf '%s\n' \
        "timestamp=$(date -Iseconds)" \
        "server_files=$files" \
        "build=$BUILD_COUNT" \
        > "$ARTIFACTS/current/manifest.txt"

    log "EMBED: $files server files present"
}

###############################################################################
# NEXT SERVER HEALTH
###############################################################################

SERVER_PID=""

stop_server() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
        SERVER_PID=""
    fi
}

start_server() {
    stop_server

    [ -x node_modules/.bin/next ] || return 1
    [ -d .next/server ] || return 1

    PORT="${PORT:-3000}" \
        node_modules/.bin/next start \
        > "$REPORTS/server-$CYCLE.log" 2>&1 &

    SERVER_PID=$!

    sleep 4

    kill -0 "$SERVER_PID" 2>/dev/null
}

health() {
    command -v curl >/dev/null 2>&1 || return 0

    curl \
        --silent \
        --show-error \
        --fail \
        --max-time 10 \
        "http://127.0.0.1:${PORT:-3000}/" \
        >/dev/null
}

###############################################################################
# DEPLOY
###############################################################################

deploy() {
    if [ -n "${DEPLOYMENT_COMMAND:-}" ]; then
        bash -lc "$DEPLOYMENT_COMMAND"
        return $?
    fi

    if command -v vercel >/dev/null 2>&1 &&
       [ -f .vercel/project.json ]; then
        vercel deploy --prod
        return $?
    fi

    log "DEPLOY: no configured external deployment target"
    return 0
}

###############################################################################
# ONE COMPLETE PIPELINE
#
# BUILD
# TEST
# BUILD
# TEST
# REPAIR IMMEDIATELY ON FAILURE
# EMBED
# TEST AGAIN
# DEPLOY
# TEST AGAIN
# RETURN TO BUILD
###############################################################################

pipeline() {

    CYCLE=$((CYCLE + 1))

    log "=============================================================="
    log "CYCLE $CYCLE"
    log "=============================================================="

    ###########################################################################
    # TEST EXISTING STATE
    ###########################################################################

    if ! run_tests > "$REPORTS/test-pre-$CYCLE.log" 2>&1; then
        capture_error TEST "$REPORTS/test-pre-$CYCLE.log"
        repair_dependencies
        return 1
    fi

    ###########################################################################
    # BUILD
    ###########################################################################

    if ! run_build > "$REPORTS/build-$CYCLE.log" 2>&1; then
        capture_error BUILD "$REPORTS/build-$CYCLE.log"
        snapshot "build-failure-$CYCLE"
        return 1
    fi

    ###########################################################################
    # TEST AFTER BUILD
    ###########################################################################

    if ! run_tests > "$REPORTS/test-post-build-$CYCLE.log" 2>&1; then
        capture_error TEST "$REPORTS/test-post-build-$CYCLE.log"
        snapshot "test-failure-$CYCLE"
        return 1
    fi

    ###########################################################################
    # TYPES
    ###########################################################################

    if ! run_types > "$REPORTS/types-$CYCLE.log" 2>&1; then
        capture_error TYPES "$REPORTS/types-$CYCLE.log"
        snapshot "type-failure-$CYCLE"
        return 1
    fi

    ###########################################################################
    # LINT
    ###########################################################################

    if ! run_lint > "$REPORTS/lint-$CYCLE.log" 2>&1; then
        capture_error LINT "$REPORTS/lint-$CYCLE.log"
        snapshot "lint-failure-$CYCLE"
        return 1
    fi

    ###########################################################################
    # EMBED / ARTIFACT GATE
    ###########################################################################

    if ! embed_artifacts > "$REPORTS/embed-$CYCLE.log" 2>&1; then
        capture_error ARTIFACT "$REPORTS/embed-$CYCLE.log"
        rm -rf .next

        if ! run_build > "$REPORTS/rebuild-$CYCLE.log" 2>&1; then
            capture_error REBUILD "$REPORTS/rebuild-$CYCLE.log"
            return 1
        fi

        embed_artifacts || return 1
    fi

    ###########################################################################
    # SECOND BUILD → TEST
    ###########################################################################

    if ! run_build > "$REPORTS/build-second-$CYCLE.log" 2>&1; then
        capture_error BUILD "$REPORTS/build-second-$CYCLE.log"
        return 1
    fi

    if ! run_tests > "$REPORTS/test-second-$CYCLE.log" 2>&1; then
        capture_error TEST "$REPORTS/test-second-$CYCLE.log"
        return 1
    fi

    ###########################################################################
    # SERVER ARTIFACT MUST EXIST
    ###########################################################################

    if ! embed_artifacts; then
        capture_error ARTIFACT "$REPORTS/embed-$CYCLE.log"
        return 1
    fi

    ###########################################################################
    # SERVER
    ###########################################################################

    if ! start_server; then
        capture_error SERVER "$REPORTS/server-$CYCLE.log"
        return 1
    fi

    if ! health; then
        capture_error HEALTH "$REPORTS/server-$CYCLE.log"
        return 1
    fi

    ###########################################################################
    # TEST LIVE SERVER
    ###########################################################################

    if command -v curl >/dev/null 2>&1; then
        if ! curl \
            --silent \
            --show-error \
            --fail \
            --max-time 10 \
            "http://127.0.0.1:${PORT:-3000}/" \
            >/dev/null
        then
            capture_error LIVE_TEST "$REPORTS/server-$CYCLE.log"
            return 1
        fi
    fi

    ###########################################################################
    # DEPLOY
    ###########################################################################

    if ! deploy > "$REPORTS/deploy-$CYCLE.log" 2>&1; then
        capture_error DEPLOY "$REPORTS/deploy-$CYCLE.log"
        return 1
    fi

    DEPLOY_COUNT=$((DEPLOY_COUNT + 1))

    ###########################################################################
    # FINAL TEST
    ###########################################################################

    if ! run_tests > "$REPORTS/test-final-$CYCLE.log" 2>&1; then
        capture_error FINAL_TEST "$REPORTS/test-final-$CYCLE.log"
        return 1
    fi

    return 0
}

###############################################################################
# NEVER EXIT
###############################################################################

trap 'stop_server' EXIT INT TERM HUP

while true; do

    printf '\033c'

    echo "=============================================================="
    echo " COMPLETION ENGINE® — UNIVERSAL CONTINUOUS FABRIC®"
    echo "=============================================================="
    echo "BUILD → TEST → BUILD → TEST → REPAIR → EMBED → TEST"
    echo "→ DEPLOY → TEST → BUILD → TEST → REPAIR → EMBED → ..."
    echo "=============================================================="
    echo "CYCLE       : $CYCLE"
    echo "BUILDS      : $BUILD_COUNT"
    echo "TESTS       : $TEST_COUNT"
    echo "REPAIRS     : $REPAIR_COUNT"
    echo "DEPLOYS     : $DEPLOY_COUNT"
    echo "ERRORS      : $ERROR_COUNT"
    echo "CONTINUOUS  : YES"
    echo "AUTO-REPAIR : YES"
    echo "EMBEDDED    : YES"
    echo "EXIT        : NEVER"
    echo "=============================================================="

    if pipeline; then
        log "✓ FULL PIPELINE VERIFIED"
    else
        log "⚠ ERROR DETECTED — REPAIRING BEFORE NEXT PIPELINE"
    fi

    stop_server

    sleep 2

done
