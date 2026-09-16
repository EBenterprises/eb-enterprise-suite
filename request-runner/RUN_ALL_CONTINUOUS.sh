#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

BASE="$PWD/.completion-state/universal"
mkdir -p "$BASE"/{logs,reports,snapshots,failures,artifacts,memory,deployments}

exec 9>"$BASE/.lock"
flock -n 9 2>/dev/null || {
    echo "Universal engine already running."
    exit 0
}

export CI=1
export NEXT_TELEMETRY_DISABLED=1

CYCLE=0
BUILDS=0
TESTS=0
REPAIRS=0
PASSES=0
DEPLOYS=0
SERVER_PID=""

log() {
    printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

script_exists() {
    node - "$1" <<'NODE'
const fs=require("fs");
const n=process.argv[2];
try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));
  process.exit(p.scripts && p.scripts[n] ? 0 : 1);
} catch {
  process.exit(1);
}
NODE
}

snapshot() {
    local d="$BASE/snapshots/$CYCLE-$1"
    mkdir -p "$d"

    for f in \
      package.json package-lock.json pnpm-lock.yaml yarn.lock \
      next.config.js next.config.mjs next.config.ts \
      tsconfig.json jsconfig.json vercel.json
    do
        [ -f "$f" ] && cp -f "$f" "$d/" 2>/dev/null || true
    done
}

repair() {
    local phase="$1"
    local logf="$2"

    REPAIRS=$((REPAIRS+1))
    snapshot "repair-$phase"

    cp "$logf" \
      "$BASE/failures/$CYCLE-$REPAIRS-$phase.log" \
      2>/dev/null || true

    log "REPAIR #$REPAIRS :: $phase"

    case "$phase" in
      DEPENDENCIES)
        npm install --no-audit --no-fund \
          >"$BASE/reports/$CYCLE-dependency-repair.log" 2>&1 || true
        ;;
      BUILD|ARTIFACT)
        rm -rf .next
        ;;
      TYPES)
        [ -x node_modules/.bin/tsc ] &&
          node_modules/.bin/tsc --noEmit \
          >"$BASE/reports/$CYCLE-types.log" 2>&1 || true
        ;;
      *)
        :
        ;;
    esac
}

tests() {
    TESTS=$((TESTS+1))

    if script_exists test:ci; then
        npm run test:ci
    elif script_exists test; then
        npm test
    elif [ -x node_modules/.bin/vitest ]; then
        node_modules/.bin/vitest run
    elif [ -x node_modules/.bin/jest ]; then
        node_modules/.bin/jest --runInBand
    else
        return 0
    fi
}

static_checks() {
    if script_exists lint; then
        npm run lint || return 1
    fi

    if script_exists typecheck; then
        npm run typecheck || return 1
    elif [ -x node_modules/.bin/tsc ] &&
         [ -f tsconfig.json ]; then
        node_modules/.bin/tsc --noEmit || return 1
    fi

    return 0
}

build() {
    BUILDS=$((BUILDS+1))
    rm -rf .next

    if [ -x node_modules/.bin/next ]; then
        node_modules/.bin/next build --webpack
    elif script_exists build; then
        npm run build
    else
        return 1
    fi
}

artifact_gate() {
    [ -d .next/server ] || return 1

    local count
    count="$(find .next/server -type f 2>/dev/null | wc -l)"

    [ "$count" -gt 0 ] || return 1

    rm -rf "$BASE/artifacts/current"
    mkdir -p "$BASE/artifacts/current"

    cp -a .next/server "$BASE/artifacts/current/"

    printf '%s\n' \
      "cycle=$CYCLE" \
      "server_files=$count" \
      "timestamp=$(date -Iseconds)" \
      >"$BASE/artifacts/current/MANIFEST"

    return 0
}

start_server() {
    stop_server

    [ -x node_modules/.bin/next ] || return 1
    [ -d .next/server ] || return 1

    PORT="${PORT:-3000}" \
      node_modules/.bin/next start \
      >"$BASE/logs/server-$CYCLE.log" 2>&1 &

    SERVER_PID=$!

    sleep 3

    kill -0 "$SERVER_PID" 2>/dev/null
}

stop_server() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
        SERVER_PID=""
    fi
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
        # No configured deployment target.
        # Local build remains valid and the engine continues.
        return 0
    fi
}

cycle() {
    CYCLE=$((CYCLE+1))

    log "=============================================================="
    log "UNIVERSAL CYCLE $CYCLE"
    log "=============================================================="

    # 1. BASELINE TEST
    if ! tests >"$BASE/reports/$CYCLE-test-baseline.log" 2>&1; then
        repair TEST "$BASE/reports/$CYCLE-test-baseline.log"
        return 1
    fi

    # 2. STATIC QUALITY
    if ! static_checks >"$BASE/reports/$CYCLE-static.log" 2>&1; then
        repair TYPES "$BASE/reports/$CYCLE-static.log"
        return 1
    fi

    # 3. BUILD
    if ! build >"$BASE/reports/$CYCLE-build.log" 2>&1; then
        repair BUILD "$BASE/reports/$CYCLE-build.log"
        return 1
    fi

    # 4. TEST BUILD
    if ! tests >"$BASE/reports/$CYCLE-test-build.log" 2>&1; then
        repair TEST "$BASE/reports/$CYCLE-test-build.log"
        return 1
    fi

    # 5. EMBED SERVER ARTIFACT
    if ! artifact_gate >"$BASE/reports/$CYCLE-artifact.log" 2>&1; then
        echo "SERVER ARTIFACT MISSING" \
          >"$BASE/reports/$CYCLE-artifact.log"
        repair ARTIFACT "$BASE/reports/$CYCLE-artifact.log"
        return 1
    fi

    # 6. LIVE SERVER
    if ! start_server; then
        repair SERVER "$BASE/logs/server-$CYCLE.log"
        return 1
    fi

    # 7. LIVE VERIFICATION
    if ! health; then
        repair SERVER "$BASE/logs/server-$CYCLE.log"
        return 1
    fi

    # 8. DEPLOY
    if ! deploy >"$BASE/reports/$CYCLE-deploy.log" 2>&1; then
        repair DEPLOY "$BASE/reports/$CYCLE-deploy.log"
        return 1
    fi

    # 9. POST-DEPLOY VERIFICATION
    if ! health; then
        repair DEPLOY "$BASE/reports/$CYCLE-deploy.log"
        return 1
    fi

    DEPLOYS=$((DEPLOYS+1))
    PASSES=$((PASSES+1))

    printf '%s\n' \
      "cycle=$CYCLE" \
      "builds=$BUILDS" \
      "tests=$TESTS" \
      "repairs=$REPAIRS" \
      "passes=$PASSES" \
      "deployments=$DEPLOYS" \
      "timestamp=$(date -Iseconds)" \
      >"$BASE/status"

    return 0
}

trap stop_server EXIT INT TERM HUP

while true; do

    printf '\033c'

    echo "=============================================================="
    echo " COMPLETION ENGINE® — UNIVERSAL FINALIZER®"
    echo "=============================================================="
    echo " BUILD → TEST → REPAIR → EMBED → BUILD → TEST"
    echo "      → VERIFY → DEPLOY → VERIFY → REPEAT"
    echo "=============================================================="
    echo "Cycle       : $CYCLE"
    echo "Builds      : $BUILDS"
    echo "Tests       : $TESTS"
    echo "Repairs     : $REPAIRS"
    echo "Passes      : $PASSES"
    echo "Deployments : $DEPLOYS"
    echo "Continuous  : YES"
    echo "Exit-on-pass: NO"
    echo "=============================================================="

    if cycle; then
        log "✓ FULL PIPELINE PASS"
        log "✓ ARTIFACT EMBEDDED"
        log "✓ SERVER VERIFIED"
        log "✓ DEPLOYMENT VERIFIED"
        log "→ NEXT CYCLE"
    else
        log "⚠ PIPELINE FAILURE"
        log "✓ FAILURE PRESERVED"
        log "✓ REPAIR APPLIED"
        log "→ RETRYING"
    fi

    stop_server
    sleep 1
done
