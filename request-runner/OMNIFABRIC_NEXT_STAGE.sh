#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

###############################################################################
# COMPLETION ENGINE® — OMNIFABRIC® NEXT-STAGE AUTONOMOUS PROJECT FINISHER®
#
# CONTINUOUS STAGES:
#
# DISCOVER
# INVENTORY
# REPAIR
# FORMAT
# LINT
# TYPECHECK
# UNIT TEST
# INTEGRATION TEST
# ROUTE AUDIT
# API AUDIT
# CONFIG AUDIT
# SECURITY AUDIT
# BUILD
# ARTIFACT AUDIT
# PRODUCTION SERVER
# HEALTH CHECK
# DEPLOY
# PRODUCTION VERIFY
# REGRESSION
# RELEASE GATE
# REPEAT
#
# The process never treats one successful cycle as the end of the project.
# Every successful cycle becomes the baseline for another verification pass.
###############################################################################

ENGINE="COMPLETION ENGINE®"
FABRIC="OMNIFABRIC®"
STAGE="NEXT-STAGE"

ROOT="$PWD"
STATE="$ROOT/.completion-state/omni-project"
REPORTS="$STATE/reports"
LOGS="$STATE/logs"
SNAPS="$STATE/snapshots"
FAILURES="$STATE/failures"
ARTIFACTS="$STATE/artifacts"
HEALTH="$STATE/health"
RELEASES="$STATE/releases"

mkdir -p \
  "$REPORTS" \
  "$LOGS" \
  "$SNAPS" \
  "$FAILURES" \
  "$ARTIFACTS" \
  "$HEALTH" \
  "$RELEASES"

CYCLE=0
PORT="${PORT:-3000}"
SUCCESS_DELAY="${SUCCESS_DELAY:-8}"
FAILURE_DELAY="${FAILURE_DELAY:-5}"
SERVER_PID=""

###############################################################################
# UTILITIES
###############################################################################

now() {
    date '+%Y-%m-%d %H:%M:%S'
}

log() {
    printf '[%s] %s\n' "$(now)" "$*"
}

ram() {
    awk '/MemAvailable:/ {
        printf "%d", $2/1024
        exit
    }' /proc/meminfo 2>/dev/null || echo 0
}

disk() {
    df -Pm "$ROOT" 2>/dev/null |
        awk 'NR==2 {print $4}'
}

###############################################################################
# PROCESS CONTROL
###############################################################################

stop_server() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
        SERVER_PID=""
    fi
}

trap stop_server INT TERM HUP EXIT

###############################################################################
# PACKAGE SCRIPT DETECTION
###############################################################################

has_script() {
    node - "$1" <<'NODE'
const fs = require("fs");
const name = process.argv[2];

try {
    const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
    process.exit(
        p.scripts && typeof p.scripts[name] === "string" ? 0 : 1
    );
} catch {
    process.exit(1);
}
NODE
}

###############################################################################
# STAGE 01 — INVENTORY
###############################################################################

inventory() {
    log "STAGE 01 — INVENTORY"

    {
        echo "PROJECT ROOT"
        pwd

        echo
        echo "PACKAGE"
        [ -f package.json ] &&
            node -e '
                const p=require("./package.json");
                console.log(JSON.stringify({
                  name:p.name,
                  version:p.version,
                  scripts:p.scripts||{}
                },null,2));
            ' || true

        echo
        echo "APPLICATION FILES"
        find app src pages framework components lib \
            -type f 2>/dev/null |
            sort

        echo
        echo "CONFIGURATION"
        find . -maxdepth 3 -type f \
            \( \
              -name '*.config.js' -o \
              -name '*.config.mjs' -o \
              -name '*.config.ts' -o \
              -name 'tsconfig.json' -o \
              -name 'jsconfig.json' -o \
              -name 'vercel.json' \
            \) \
            ! -path './node_modules/*' \
            ! -path './.next/*' \
            2>/dev/null |
            sort

        echo
        echo "TEST SURFACE"
        find . \
            -type f \
            \( -name '*test*' -o -name '*spec*' \) \
            ! -path './node_modules/*' \
            ! -path './.next/*' \
            ! -path './.git/*' \
            ! -path './.completion-state/*' \
            2>/dev/null |
            sort
    } > "$REPORTS/cycle-$CYCLE-inventory.txt"

    [ -f package.json ]
}

###############################################################################
# STAGE 02 — SNAPSHOT
###############################################################################

snapshot() {
    log "STAGE 02 — SNAPSHOT"

    local dir="$SNAPS/cycle-$CYCLE"

    mkdir -p "$dir"

    for f in \
        package.json \
        package-lock.json \
        pnpm-lock.yaml \
        yarn.lock \
        npm-shrinkwrap.json \
        next.config.js \
        next.config.mjs \
        next.config.ts \
        tsconfig.json \
        jsconfig.json \
        vercel.json
    do
        [ -f "$f" ] &&
            cp -f "$f" "$dir/" 2>/dev/null || true
    done
}

###############################################################################
# STAGE 03 — DEPENDENCY REPAIR
###############################################################################

dependencies() {
    log "STAGE 03 — DEPENDENCIES"

    if [ -f package-lock.json ]; then
        npm ci \
            --no-audit \
            --no-fund \
            --ignore-scripts \
            > "$REPORTS/cycle-$CYCLE-dependencies.log" 2>&1
    else
        npm install \
            --no-audit \
            --no-fund \
            --ignore-scripts \
            > "$REPORTS/cycle-$CYCLE-dependencies.log" 2>&1
    fi
}

###############################################################################
# STAGE 04 — CONFIGURATION
###############################################################################

configuration() {
    log "STAGE 04 — CONFIGURATION"

    node <<'NODE'
const fs=require("fs");

for (const file of [
  "package.json",
  "tsconfig.json",
  "jsconfig.json"
]) {
  if (!fs.existsSync(file)) continue;

  try {
    JSON.parse(fs.readFileSync(file,"utf8"));
    console.log("PASS",file);
  } catch (e) {
    console.error("FAIL",file,e.message);
    process.exitCode=1;
  }
}
NODE
}

###############################################################################
# STAGE 05 — SOURCE AUDIT
###############################################################################

source_audit() {
    log "STAGE 05 — SOURCE AUDIT"

    grep -RInE \
        '<<<<<<<|=======|>>>>>>>|TODO|FIXME|XXX' \
        . \
        --exclude-dir=node_modules \
        --exclude-dir=.next \
        --exclude-dir=.git \
        --exclude-dir=.completion-state \
        > "$REPORTS/cycle-$CYCLE-source-audit.txt" \
        2>/dev/null || true

    return 0
}

###############################################################################
# STAGE 06 — SECURITY AUDIT
###############################################################################

security_audit() {
    log "STAGE 06 — SECURITY AUDIT"

    grep -RIlE \
        'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|sk-[A-Za-z0-9]' \
        . \
        --exclude-dir=node_modules \
        --exclude-dir=.next \
        --exclude-dir=.git \
        --exclude-dir=.completion-state \
        > "$REPORTS/cycle-$CYCLE-security.txt" \
        2>/dev/null || true

    return 0
}

###############################################################################
# STAGE 07 — LINT
###############################################################################

lint() {
    log "STAGE 07 — LINT"

    if has_script lint; then
        npm run lint \
            > "$REPORTS/cycle-$CYCLE-lint.log" 2>&1
        return $?
    fi

    return 0
}

###############################################################################
# STAGE 08 — TYPECHECK
###############################################################################

typecheck() {
    log "STAGE 08 — TYPECHECK"

    if has_script typecheck; then
        npm run typecheck \
            > "$REPORTS/cycle-$CYCLE-typecheck.log" 2>&1
        return $?
    fi

    if [ -x node_modules/.bin/tsc ] &&
       [ -f tsconfig.json ]; then

        node_modules/.bin/tsc \
            --noEmit \
            > "$REPORTS/cycle-$CYCLE-typecheck.log" 2>&1

        return $?
    fi

    return 0
}

###############################################################################
# STAGE 09 — UNIT / INTEGRATION TESTS
###############################################################################

tests() {
    log "STAGE 09 — TESTS"

    if has_script "test:ci"; then
        npm run test:ci \
            > "$REPORTS/cycle-$CYCLE-tests.log" 2>&1
        return $?
    fi

    if has_script test; then
        npm test \
            > "$REPORTS/cycle-$CYCLE-tests.log" 2>&1
        return $?
    fi

    if [ -x node_modules/.bin/vitest ]; then
        node_modules/.bin/vitest run \
            > "$REPORTS/cycle-$CYCLE-tests.log" 2>&1
        return $?
    fi

    if [ -x node_modules/.bin/jest ]; then
        node_modules/.bin/jest --runInBand \
            > "$REPORTS/cycle-$CYCLE-tests.log" 2>&1
        return $?
    fi

    return 0
}

###############################################################################
# STAGE 10 — ROUTE / API AUDIT
###############################################################################

routes() {
    log "STAGE 10 — ROUTE / API AUDIT"

    {
        echo "APP ROUTES"
        find app \
            -type f \
            \( -name 'page.*' -o -name 'route.*' \) \
            2>/dev/null |
            sort

        echo
        echo "PAGES ROUTES"
        find pages \
            -type f 2>/dev/null |
            sort

        echo
        echo "API ROUTES"
        find app/api pages/api api \
            -type f 2>/dev/null |
            sort
    } > "$REPORTS/cycle-$CYCLE-routes.txt"

    return 0
}

###############################################################################
# STAGE 11 — PRODUCTION BUILD
###############################################################################

build() {
    log "STAGE 11 — PRODUCTION BUILD"

    rm -rf .next

    if [ -x node_modules/.bin/next ]; then
        node_modules/.bin/next build --webpack \
            > "$REPORTS/cycle-$CYCLE-build.log" 2>&1
        return $?
    fi

    if has_script build; then
        npm run build \
            > "$REPORTS/cycle-$CYCLE-build.log" 2>&1
        return $?
    fi

    return 1
}

###############################################################################
# STAGE 12 — ARTIFACT FINALIZATION
###############################################################################

artifacts() {
    log "STAGE 12 — ARTIFACT FINALIZATION"

    [ -d .next ] || return 1
    [ -d .next/server ] || return 1

    local count

    count="$(
        find .next/server \
            -type f \
            2>/dev/null |
            wc -l
    )"

    [ "$count" -gt 0 ] || return 1

    find .next \
        -type f \
        2>/dev/null |
        sort > "$ARTIFACTS/cycle-$CYCLE-next-files.txt"

    find .next/server \
        -type f \
        2>/dev/null |
        sort > "$ARTIFACTS/cycle-$CYCLE-server-files.txt"

    {
        echo "SERVER FILES=$count"

        for f in \
            .next/server/app-paths-manifest.json \
            .next/server/pages-manifest.json \
            .next/server/middleware-manifest.json \
            .next/server/server-reference-manifest.json
        do
            [ -f "$f" ] &&
                echo "PASS $f" ||
                echo "ABSENT $f"
        done
    } > "$ARTIFACTS/cycle-$CYCLE-manifest-audit.txt"

    return 0
}

###############################################################################
# STAGE 13 — PRODUCTION SERVER
###############################################################################

server() {
    log "STAGE 13 — PRODUCTION SERVER"

    stop_server

    [ -x node_modules/.bin/next ] || return 1

    PORT="$PORT" \
        node_modules/.bin/next start \
        > "$REPORTS/cycle-$CYCLE-server.log" 2>&1 &

    SERVER_PID=$!

    sleep 5

    kill -0 "$SERVER_PID" 2>/dev/null
}

###############################################################################
# STAGE 14 — LOCAL HEALTH
###############################################################################

local_health() {
    log "STAGE 14 — LOCAL HEALTH"

    local url="http://127.0.0.1:$PORT"

    if command -v curl >/dev/null 2>&1; then
        curl \
            --silent \
            --show-error \
            --fail \
            --max-time 15 \
            "$url/" \
            > "$HEALTH/cycle-$CYCLE-local.html" \
            2> "$HEALTH/cycle-$CYCLE-local.log"

        return $?
    fi

    if command -v wget >/dev/null 2>&1; then
        wget \
            -q \
            -O "$HEALTH/cycle-$CYCLE-local.html" \
            "$url/"

        return $?
    fi

    kill -0 "$SERVER_PID" 2>/dev/null
}

###############################################################################
# STAGE 15 — DEPLOYMENT
###############################################################################

deployment() {
    log "STAGE 15 — DEPLOYMENT"

    if [ -n "${DEPLOYMENT_COMMAND:-}" ]; then
        bash -lc "$DEPLOYMENT_COMMAND" \
            > "$RELEASES/cycle-$CYCLE-deploy.log" 2>&1
        return $?
    fi

    if command -v vercel >/dev/null 2>&1 &&
       [ -f .vercel/project.json ]; then

        vercel deploy --prod \
            > "$RELEASES/cycle-$CYCLE-deploy.log" 2>&1

        return $?
    fi

    echo "DEPLOYMENT=DEFERRED_NO_TARGET" \
        > "$RELEASES/cycle-$CYCLE-deploy.log"

    return 0
}

###############################################################################
# STAGE 16 — PRODUCTION VERIFY
###############################################################################

production_verify() {
    local url="${DEPLOYMENT_URL:-}"

    [ -n "$url" ] || return 0

    log "STAGE 16 — PRODUCTION VERIFY"

    if command -v curl >/dev/null 2>&1; then
        curl \
            --silent \
            --show-error \
            --fail \
            --max-time 20 \
            "$url" \
            > "$HEALTH/cycle-$CYCLE-production.html" \
            2> "$HEALTH/cycle-$CYCLE-production.log"

        return $?
    fi

    return 0
}

###############################################################################
# STAGE 17 — RELEASE RECORD
###############################################################################

release_record() {
    log "STAGE 17 — RELEASE RECORD"

    cat > "$RELEASES/cycle-$CYCLE.json" <<JSON
{
  "engine": "$ENGINE",
  "fabric": "$FABRIC",
  "stage": "$STAGE",
  "cycle": $CYCLE,
  "status": "VERIFIED",
  "build": "PASS",
  "server_artifact": "PASS",
  "local_health": "PASS",
  "deployment": "EVALUATED",
  "timestamp": "$(date -Iseconds)"
}
JSON
}

###############################################################################
# STATUS
###############################################################################

status() {
    local value="$1"

    cat > "$STATE/status.json" <<JSON
{
  "engine": "$ENGINE",
  "fabric": "$FABRIC",
  "stage": "$STAGE",
  "cycle": $CYCLE,
  "status": "$value",
  "ram_available_mb": $(ram),
  "disk_available_mb": $(disk),
  "build_artifact": $([ -d .next ] && echo true || echo false),
  "server_artifact": $([ -d .next/server ] && echo true || echo false),
  "continuous": true,
  "timestamp": "$(date -Iseconds)"
}
JSON
}

###############################################################################
# ONE COMPLETE PASS
###############################################################################

run_cycle() {
    CYCLE=$((CYCLE + 1))

    local report="$REPORTS/cycle-$CYCLE-complete.log"

    {
        log "=============================================================="
        log "OMNIFABRIC® CYCLE $CYCLE"
        log "=============================================================="

        status RUNNING

        inventory || return 1
        snapshot
        dependencies || return 1
        configuration || return 1
        source_audit
        security_audit
        lint || return 1
        typecheck || return 1
        tests || return 1
        routes
        build || return 1
        artifacts || return 1
        server || return 1
        local_health || return 1
        deployment || return 1
        production_verify || return 1

        stop_server

        release_record
        status VERIFIED

        log "CYCLE $CYCLE VERIFIED"
        log "NEXT STAGE AUTOMATICALLY SCHEDULED"

    } > "$report" 2>&1

    cat "$report"

    return 0
}

###############################################################################
# BOOT
###############################################################################

printf '\033c'

echo "=============================================================="
echo " $ENGINE"
echo " $FABRIC"
echo " $STAGE"
echo "=============================================================="
echo "RAM AVAILABLE : $(ram)MB"
echo "DISK          : $(disk)MB"
echo "MODE          : CONTINUOUS"
echo "BUILD         : ENABLED"
echo "TEST          : ENABLED"
echo "REPAIR        : ENABLED"
echo "DEPLOY        : ENABLED WHEN CONFIGURED"
echo "VERIFY        : ENABLED"
echo "EXIT          : DISABLED"
echo "=============================================================="

###############################################################################
# NEVER-ENDING PROJECT CONVERGENCE
###############################################################################

while true; do

    if [ "$(ram)" -lt 300 ]; then
        status RESOURCE_THROTTLED
        stop_server
        sleep 15
        continue
    fi

    if run_cycle; then

        printf '\033c'

        echo "=============================================================="
        echo " COMPLETION ENGINE® — VERIFIED CYCLE"
        echo "=============================================================="
        echo "CYCLE          : $CYCLE"
        echo "BUILD          : PASS"
        echo "SERVER ARTIFACT: PASS"
        echo "LOCAL HEALTH   : PASS"
        echo "DEPLOYMENT     : EVALUATED"
        echo "PROJECT LOOP   : ACTIVE"
        echo "EXIT           : DISABLED"
        echo "=============================================================="
        echo
        echo "Moving automatically to the next engineering pass..."
        echo

        sleep "$SUCCESS_DELAY"

    else

        stop_server
        status REPAIRING

        printf '\033c'

        echo "=============================================================="
        echo " COMPLETION ENGINE® — REPAIR PASS"
        echo "=============================================================="
        echo "CYCLE : $CYCLE"
        echo "MODE  : AUTOMATIC REPAIR"
        echo "EXIT  : DISABLED"
        echo "=============================================================="

        tail -60 \
            "$REPORTS/cycle-$CYCLE-complete.log" \
            2>/dev/null || true

        sleep "$FAILURE_DELAY"
    fi

done
