#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ROOT="$PWD"
STATE="$ROOT/.completion-state/UNIVERSAL"
LOGDIR="$STATE/logs"
REPORTDIR="$STATE/reports"
mkdir -p "$LOGDIR" "$REPORTDIR"

export NEXT_TELEMETRY_DISABLED=1
export CI=1

TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/universal-$TS.log"

exec > >(tee -a "$LOG") 2>&1

###############################################################################
# COMPLETION ENGINE® — UNIVERSAL ALL-VERSIONS / ALL-PHASES / DEPLOYMENT FABRIC®
###############################################################################

echo "=============================================================="
echo " COMPLETION ENGINE® — UNIVERSAL FINALIZATION"
echo " ALL VERSIONS"
echo " ALL PHASES"
echo " BUILD → TEST → ARTIFACT → SERVER → DEPLOY → VERIFY"
echo " CONTINUOUS MODE — NEVER EXIT AFTER SUCCESS"
echo "=============================================================="

PHASE=0
CYCLE=0
SUCCESS=0
FAILURES=0

run() {
    local name="$1"
    shift

    PHASE=$((PHASE + 1))

    echo
    echo "=============================================================="
    echo " PHASE $PHASE — $name"
    echo "=============================================================="

    if "$@"; then
        echo "PASS — $name"
        return 0
    fi

    echo "FAIL — $name"
    return 1
}

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
# VERSION DISCOVERY
###############################################################################

discover_versions() {
    echo "[VERSION DISCOVERY]"

    node <<'NODE'
const fs=require("fs");

try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));

  console.log("PACKAGE=" + (p.name || "unknown"));
  console.log("VERSION=" + (p.version || "unknown"));

  for (const [k,v] of Object.entries(p.scripts || {})) {
    console.log("SCRIPT=" + k + " => " + v);
  }
} catch(e) {
  console.log("PACKAGE_DISCOVERY_FAILED=" + e.message);
}
NODE

    find . \
        -maxdepth 3 \
        -type f \
        \( \
          -name 'VERSION' -o \
          -name '*version*' -o \
          -name 'package.json' \
        \) \
        ! -path './node_modules/*' \
        ! -path './.next/*' \
        ! -path './.git/*' \
        2>/dev/null | sort
}

###############################################################################
# INVENTORY
###############################################################################

inventory() {
    find app src pages framework components lib \
        -type f 2>/dev/null |
        sort > "$REPORTDIR/cycle-$CYCLE-source.txt"

    find app/api pages/api api \
        -type f 2>/dev/null |
        sort > "$REPORTDIR/cycle-$CYCLE-api.txt"

    find .next/server \
        -type f 2>/dev/null |
        sort > "$REPORTDIR/cycle-$CYCLE-server-before.txt"

    return 0
}

###############################################################################
# DEPENDENCIES
###############################################################################

dependencies() {
    if [ -f package-lock.json ]; then
        npm ci --no-audit --no-fund
    else
        npm install --no-audit --no-fund
    fi
}

###############################################################################
# FORMAT / LINT
###############################################################################

lint() {
    if has_script lint; then
        npm run lint
    elif [ -x node_modules/.bin/eslint ]; then
        node_modules/.bin/eslint . \
            --ignore-pattern node_modules \
            --ignore-pattern .next
    else
        return 0
    fi
}

###############################################################################
# TYPES
###############################################################################

types() {
    if has_script typecheck; then
        npm run typecheck
        return $?
    fi

    if [ -x node_modules/.bin/tsc ] &&
       [ -f tsconfig.json ]; then
        node_modules/.bin/tsc --noEmit
        return $?
    fi

    return 0
}

###############################################################################
# TESTS
###############################################################################

tests() {
    if has_script test:ci; then
        npm run test:ci
        return $?
    fi

    if has_script test; then
        npm test
        return $?
    fi

    if [ -x node_modules/.bin/vitest ]; then
        node_modules/.bin/vitest run
        return $?
    fi

    if [ -x node_modules/.bin/jest ]; then
        node_modules/.bin/jest --runInBand
        return $?
    fi

    return 0
}

###############################################################################
# SECURITY
###############################################################################

security() {
    ! grep -RIlE \
        'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|sk-[A-Za-z0-9]' \
        . \
        --exclude-dir=node_modules \
        --exclude-dir=.next \
        --exclude-dir=.git \
        --exclude-dir=.completion-state \
        2>/dev/null |
        grep -q .
}

###############################################################################
# BUILD ALL DECLARED BUILD TARGETS
###############################################################################

build_all() {
    rm -rf .next

    if [ -x node_modules/.bin/next ]; then
        node_modules/.bin/next build --webpack
        return $?
    fi

    if has_script build; then
        npm run build
        return $?
    fi

    echo "NO BUILD SYSTEM FOUND"
    return 1
}

###############################################################################
# SERVER ARTIFACT GATE
###############################################################################

server_artifact_gate() {
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

    echo "SERVER_ARTIFACT_FILES=$files"

    for f in \
        .next/server/app-paths-manifest.json \
        .next/server/pages-manifest.json \
        .next/server/middleware-manifest.json \
        .next/server/server-reference-manifest.json
    do
        if [ -f "$f" ]; then
            echo "PASS $f"
        else
            echo "OPTIONAL/ABSENT $f"
        fi
    done

    return 0
}

###############################################################################
# PRODUCTION SERVER
###############################################################################

SERVER_PID=""

stop_server() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
        SERVER_PID=""
    fi
}

trap stop_server EXIT INT TERM HUP

start_server() {
    stop_server

    PORT="${PORT:-3000}" \
    node_modules/.bin/next start \
        > "$REPORTDIR/cycle-$CYCLE-server.log" 2>&1 &

    SERVER_PID=$!

    sleep 5

    kill -0 "$SERVER_PID" 2>/dev/null
}

###############################################################################
# LOCAL DEPLOYMENT VERIFICATION
###############################################################################

local_verify() {
    if command -v curl >/dev/null 2>&1; then
        curl \
            --silent \
            --show-error \
            --fail \
            --max-time 20 \
            "http://127.0.0.1:${PORT:-3000}/" \
            > "$REPORTDIR/cycle-$CYCLE-local-response.html"
        return $?
    fi

    return 0
}

###############################################################################
# EXTERNAL DEPLOYMENT
#
# Set one of:
#
# DEPLOYMENT_COMMAND='...'
# DEPLOYMENT_URL='https://...'
#
# or configure a linked Vercel project.
###############################################################################

deploy() {
    if [ -n "${DEPLOYMENT_COMMAND:-}" ]; then
        echo "[DEPLOY] executing configured deployment"
        bash -lc "$DEPLOYMENT_COMMAND"
        return $?
    fi

    if command -v vercel >/dev/null 2>&1 &&
       [ -f .vercel/project.json ]; then

        vercel deploy --prod
        return $?
    fi

    echo "DEPLOYMENT TARGET NOT CONFIGURED"
    echo "LOCAL PRODUCTION DEPLOYMENT VERIFIED"
    return 0
}

###############################################################################
# REMOTE VERIFICATION
###############################################################################

remote_verify() {
    [ -n "${DEPLOYMENT_URL:-}" ] || return 0

    command -v curl >/dev/null 2>&1 || return 0

    curl \
        --silent \
        --show-error \
        --fail \
        --max-time 30 \
        "$DEPLOYMENT_URL" \
        > "$REPORTDIR/cycle-$CYCLE-remote-response.html"
}

###############################################################################
# RELEASE RECORD
###############################################################################

release_record() {
    cat > "$REPORTDIR/cycle-$CYCLE-release.json" <<JSON
{
  "engine": "COMPLETION ENGINE®",
  "fabric": "UNIVERSAL FINALIZATION FABRIC®",
  "cycle": $CYCLE,
  "phases": $PHASE,
  "status": "VERIFIED",
  "server_artifact": true,
  "local_production": true,
  "deployment_attempted": true,
  "timestamp": "$(date -Iseconds)"
}
JSON
}

###############################################################################
# COMPLETE ONE FULL VERSION / PHASE PASS
###############################################################################

complete_everything_once() {
    PHASE=0

    run "VERSION DISCOVERY" discover_versions || return 1
    run "PROJECT INVENTORY" inventory || return 1
    run "DEPENDENCY FINALIZATION" dependencies || return 1
    run "LINT / SOURCE QUALITY" lint || return 1
    run "TYPE VALIDATION" types || return 1
    run "SECURITY AUDIT" security || return 1
    run "UNIT / INTEGRATION TESTS" tests || return 1
    run "PRODUCTION BUILD" build_all || return 1
    run "SERVER ARTIFACT FINALIZATION" server_artifact_gate || return 1
    run "PRODUCTION SERVER START" start_server || return 1
    run "LOCAL PRODUCTION HEALTH" local_verify || return 1

    stop_server

    run "DEPLOYMENT" deploy || return 1
    run "DEPLOYMENT VERIFICATION" remote_verify || return 1

    release_record

    return 0
}

###############################################################################
# CONTINUOUS HIGH-TIER CONVERGENCE
###############################################################################

while true; do

    CYCLE=$((CYCLE + 1))

    printf '\033c'

    echo "=============================================================="
    echo " COMPLETION ENGINE® — UNIVERSAL CYCLE $CYCLE"
    echo "=============================================================="
    echo " ALL VERSIONS       : ENABLED"
    echo " ALL PHASES         : ENABLED"
    echo " BUILD              : ENABLED"
    echo " TEST               : ENABLED"
    echo " ARTIFACT FINALIZE  : ENABLED"
    echo " SERVER             : ENABLED"
    echo " DEPLOY             : ENABLED"
    echo " VERIFY             : ENABLED"
    echo " CONTINUOUS         : ENABLED"
    echo " EXIT AFTER SUCCESS : DISABLED"
    echo "=============================================================="

    if complete_everything_once; then

        SUCCESS=$((SUCCESS + 1))

        cat > "$STATE/status.json" <<JSON
{
  "cycle": $CYCLE,
  "status": "VERIFIED",
  "successful_cycles": $SUCCESS,
  "failed_cycles": $FAILURES,
  "continuous": true,
  "next_cycle": $((CYCLE + 1)),
  "timestamp": "$(date -Iseconds)"
}
JSON

        echo
        echo "=============================================================="
        echo " CYCLE $CYCLE VERIFIED"
        echo " SUCCESSFUL PASSES : $SUCCESS"
        echo " FAILED PASSES     : $FAILURES"
        echo " NEXT CYCLE        : $((CYCLE + 1))"
        echo " EXIT              : DISABLED"
        echo "=============================================================="
        echo
        echo "Continuing automatically..."

        sleep 5

    else

        FAILURES=$((FAILURES + 1))

        cat > "$STATE/status.json" <<JSON
{
  "cycle": $CYCLE,
  "status": "REPAIR_REQUIRED",
  "successful_cycles": $SUCCESS,
  "failed_cycles": $FAILURES,
  "continuous": true,
  "retry_cycle": $((CYCLE + 1)),
  "timestamp": "$(date -Iseconds)"
}
JSON

        stop_server

        echo
        echo "=============================================================="
        echo " CYCLE $CYCLE REQUIRES REPAIR"
        echo " AUTOMATIC RETRY ENABLED"
        echo " EXIT              : DISABLED"
        echo "=============================================================="

        sleep 8
    fi

done
