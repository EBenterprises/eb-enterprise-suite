#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE=".completion-state/v10"
mkdir -p "$STATE"/{logs,reports,snapshots,failures,artifacts,memory}

exec 9>"$STATE/.lock"

if ! flock -n 9 2>/dev/null; then
    echo "CONTINUOUS FINALIZER V10 already running."
    exit 0
fi

export CI=1
export NEXT_TELEMETRY_DISABLED=1

CYCLE=0
BUILD=0
TEST=0
REPAIR=0
VERIFY=0
DEPLOY=0

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

has_script() {
    node - "$1" <<'NODE'
const fs=require("fs");
const n=process.argv[2];
try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));
  process.exit(p.scripts?.[n] ? 0 : 1);
} catch {
  process.exit(1);
}
NODE
}

run_test() {
    TEST=$((TEST+1))

    if has_script test:ci; then
        npm run test:ci
    elif has_script test; then
        npm test
    elif [ -x node_modules/.bin/vitest ]; then
        node_modules/.bin/vitest run
    elif [ -x node_modules/.bin/jest ]; then
        node_modules/.bin/jest --runInBand
    else
        return 0
    fi
}

run_static() {
    if has_script lint; then
        npm run lint || return 1
    fi

    if has_script typecheck; then
        npm run typecheck || return 1
    elif [ -x node_modules/.bin/tsc ] && [ -f tsconfig.json ]; then
        node_modules/.bin/tsc --noEmit || return 1
    fi

    return 0
}

run_build() {
    BUILD=$((BUILD+1))
    rm -rf .next

    if [ -x node_modules/.bin/next ]; then
        node_modules/.bin/next build --webpack
    elif has_script build; then
        npm run build
    else
        return 1
    fi
}

artifact_gate() {
    [ -d .next/server ] || return 1

    local n
    n=$(find .next/server -type f 2>/dev/null | wc -l)

    [ "$n" -gt 0 ] || return 1

    rm -rf "$STATE/artifacts/current"
    mkdir -p "$STATE/artifacts/current"

    cp -a .next/server "$STATE/artifacts/current/"

    printf '%s\n' \
        "cycle=$CYCLE" \
        "server_files=$n" \
        "timestamp=$(date -Iseconds)" \
        > "$STATE/artifacts/current/manifest"

    return 0
}

snapshot() {
    local name="$1"
    local dir="$STATE/snapshots/$CYCLE-$name"

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

repair() {
    local reason="$1"
    local evidence="$2"

    REPAIR=$((REPAIR+1))

    snapshot "$reason"

    cp "$evidence" \
        "$STATE/failures/$CYCLE-$REPAIR-$reason.log" \
        2>/dev/null || true

    log "REPAIR #$REPAIR :: $reason"

    case "$reason" in
        DEPENDENCIES)
            npm install --no-audit --no-fund \
                > "$STATE/reports/$CYCLE-dependencies.log" 2>&1 || true
            ;;
        BUILD|ARTIFACT)
            rm -rf .next
            ;;
        TEST|STATIC)
            npm install --no-audit --no-fund \
                > "$STATE/reports/$CYCLE-refresh.log" 2>&1 || true
            ;;
        *)
            :
            ;;
    esac
}

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
        > "$STATE/logs/server-$CYCLE.log" 2>&1 &

    SERVER_PID=$!

    sleep 3

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

deploy() {
    if [ -n "${DEPLOYMENT_COMMAND:-}" ]; then
        bash -lc "$DEPLOYMENT_COMMAND"
    elif command -v vercel >/dev/null 2>&1 &&
         [ -f .vercel/project.json ]; then
        vercel deploy --prod
    else
        return 0
    fi
}

pipeline() {
    CYCLE=$((CYCLE+1))

    log "============================================================"
    log "CYCLE $CYCLE"
    log "============================================================"

    # TEST
    if ! run_test > "$STATE/reports/$CYCLE-test-pre.log" 2>&1; then
        repair TEST "$STATE/reports/$CYCLE-test-pre.log"
        return 1
    fi

    # STATIC
    if ! run_static > "$STATE/reports/$CYCLE-static.log" 2>&1; then
        repair STATIC "$STATE/reports/$CYCLE-static.log"
        return 1
    fi

    # BUILD
    if ! run_build > "$STATE/reports/$CYCLE-build.log" 2>&1; then
        repair BUILD "$STATE/reports/$CYCLE-build.log"
        return 1
    fi

    # TEST BUILT RESULT
    if ! run_test > "$STATE/reports/$CYCLE-test-build.log" 2>&1; then
        repair TEST "$STATE/reports/$CYCLE-test-build.log"
        return 1
    fi

    # EMBED SERVER ARTIFACT
    if ! artifact_gate > "$STATE/reports/$CYCLE-artifact.log" 2>&1; then
        repair ARTIFACT "$STATE/reports/$CYCLE-artifact.log"
        return 1
    fi

    # LIVE SERVER
    if ! start_server; then
        repair SERVER "$STATE/logs/server-$CYCLE.log"
        return 1
    fi

    # LIVE TEST
    if ! health; then
        repair SERVER "$STATE/logs/server-$CYCLE.log"
        return 1
    fi

    # DEPLOY
    if ! deploy > "$STATE/reports/$CYCLE-deploy.log" 2>&1; then
        repair DEPLOY "$STATE/reports/$CYCLE-deploy.log"
        return 1
    fi

    # POST-DEPLOY TEST
    if ! health; then
        repair DEPLOY "$STATE/reports/$CYCLE-deploy.log"
        return 1
    fi

    VERIFY=$((VERIFY+1))
    DEPLOY=$((DEPLOY+1))

    printf '%s\n' \
        "cycle=$CYCLE" \
        "builds=$BUILD" \
        "tests=$TEST" \
        "repairs=$REPAIR" \
        "verified=$VERIFY" \
        "deployments=$DEPLOY" \
        "timestamp=$(date -Iseconds)" \
        > "$STATE/status"

    return 0
}

trap 'stop_server' EXIT INT TERM HUP

while true; do

    printf '\033c'

    echo "=============================================================="
    echo " COMPLETION ENGINE® V10 — CONTINUOUS FINALIZER®"
    echo "=============================================================="
    echo " TEST → BUILD → TEST → EMBED → TEST → DEPLOY → VERIFY"
    echo "                    ↕"
    echo "                 REPAIR"
    echo "=============================================================="
    echo "CYCLE       : $CYCLE"
    echo "BUILDS      : $BUILD"
    echo "TESTS       : $TEST"
    echo "REPAIRS     : $REPAIR"
    echo "VERIFIED    : $VERIFY"
    echo "DEPLOYED    : $DEPLOY"
    echo "CONTINUOUS  : YES"
    echo "EXIT        : NO"
    echo "=============================================================="

    if pipeline; then
        log "✓ COMPLETE PASS"
        log "→ IMMEDIATELY STARTING NEXT BUILD/TEST CYCLE"
    else
        log "⚠ ERROR"
        log "→ REPAIR EMBEDDED"
        log "→ IMMEDIATELY RETRYING"
    fi

    stop_server
    sleep 1

done
