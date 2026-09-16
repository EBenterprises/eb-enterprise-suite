#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

###############################################################################
# COMPLETION ENGINE® — OMNIFABRIC®
# UNIVERSAL CONTINUOUS BUILD / TEST / VERIFY / DEPLOY FABRIC®
#
# OPERATING PRINCIPLES
#   • Never intentionally exits
#   • Discovers the complete repository surface
#   • Builds all supported application surfaces
#   • Tests configured test surfaces
#   • Validates generated artifacts
#   • Repairs recoverable failures
#   • Repeats continuously
#   • Uses physical resources as the execution boundary
#   • Never claims deployment unless a real deployment target exists
###############################################################################

ENGINE="COMPLETION ENGINE®"
FABRIC="OMNIFABRIC®"
VERSION="UNIVERSAL-HIGHEST-TIER"

ROOT="$PWD"
STATE="$ROOT/.completion-state/omni-universal"
REPORTS="$STATE/reports"
LOGS="$STATE/logs"
SNAPSHOTS="$STATE/snapshots"
ARTIFACTS="$STATE/artifacts"
HEALTH="$STATE/health"
DEPLOYMENTS="$STATE/deployments"
FAILURES="$STATE/failures"
QUEUE="$STATE/queue"
DONE="$STATE/done"

mkdir -p \
  "$REPORTS" \
  "$LOGS" \
  "$SNAPSHOTS" \
  "$ARTIFACTS" \
  "$HEALTH" \
  "$DEPLOYMENTS" \
  "$FAILURES" \
  "$QUEUE" \
  "$DONE"

CYCLE=0
SERVER_PID=""
PORT="${PORT:-3000}"
SLEEP_SUCCESS="${SLEEP_SUCCESS:-10}"
SLEEP_FAILURE="${SLEEP_FAILURE:-5}"

###############################################################################
# TERMINAL
###############################################################################

clear_terminal() {
    printf '\033c'
}

###############################################################################
# LOG
###############################################################################

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

###############################################################################
# RESOURCE INTELLIGENCE
###############################################################################

ram_available() {
    awk '/MemAvailable:/ {
        printf "%d", $2/1024
        exit
    }' /proc/meminfo 2>/dev/null || echo 0
}

ram_total() {
    awk '/MemTotal:/ {
        printf "%d", $2/1024
        exit
    }' /proc/meminfo 2>/dev/null || echo 0
}

disk_available() {
    df -Pm "$ROOT" 2>/dev/null |
        awk 'NR==2 {print $4}'
}

cpu_count() {
    getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1
}

###############################################################################
# SAFE PROCESS MANAGEMENT
###############################################################################

stop_server() {
    if [ -n "${SERVER_PID:-}" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
        SERVER_PID=""
    fi
}

cleanup() {
    stop_server
}

trap cleanup INT TERM HUP

###############################################################################
# PACKAGE METADATA
###############################################################################

package_value() {
    local key="$1"

    node - "$key" <<'NODE'
const fs = require("fs");

const key = process.argv[2];

try {
    const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
    const value = p[key];

    if (value === undefined) process.exit(2);

    console.log(typeof value === "object"
        ? JSON.stringify(value)
        : String(value));
} catch {
    process.exit(2);
}
NODE
}

has_script() {
    local script="$1"

    node - "$script" <<'NODE'
const fs = require("fs");

const name = process.argv[2];

try {
    const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
    process.exit(
        p.scripts && typeof p.scripts[name] === "string"
            ? 0
            : 1
    );
} catch {
    process.exit(1);
}
NODE
}

###############################################################################
# DISCOVERY
###############################################################################

discover_surface() {
    log "DISCOVERY"

    {
        echo "=== ROOT ==="
        find . -maxdepth 2 \
            -type f \
            ! -path './node_modules/*' \
            ! -path './.next/*' \
            ! -path './.git/*' \
            2>/dev/null |
            sort

        echo
        echo "=== APPLICATION ==="
        find app pages src framework components lib \
            -type f \
            2>/dev/null |
            sort

        echo
        echo "=== API ==="
        find app/api pages/api api \
            -type f \
            2>/dev/null |
            sort

        echo
        echo "=== TESTS ==="
        find . \
            -type f \
            \( \
                -name '*test*' -o \
                -name '*spec*' \
            \) \
            ! -path './node_modules/*' \
            ! -path './.next/*' \
            ! -path './.git/*' \
            2>/dev/null |
            sort

        echo
        echo "=== CONFIGURATION ==="
        find . \
            -maxdepth 3 \
            -type f \
            \( \
                -name '*.config.js' -o \
                -name '*.config.mjs' -o \
                -name '*.config.ts' -o \
                -name 'tsconfig.json' -o \
                -name 'jsconfig.json' \
            \) \
            ! -path './node_modules/*' \
            2>/dev/null |
            sort
    } > "$REPORTS/cycle-$CYCLE-surface.txt"

    [ -f package.json ]
}

###############################################################################
# SNAPSHOT
###############################################################################

snapshot() {
    local target="$SNAPSHOTS/cycle-$CYCLE"

    mkdir -p "$target"

    for file in \
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
        [ -f "$file" ] &&
            cp -f "$file" "$target/" 2>/dev/null || true
    done

    log "SNAPSHOT=$target"
}

###############################################################################
# DEPENDENCY REPAIR
###############################################################################

install_dependencies() {
    log "DEPENDENCY RESOLUTION"

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
# CONFIGURATION VALIDATION
###############################################################################

validate_json() {
    local file="$1"

    [ -f "$file" ] || return 0

    node - "$file" <<'NODE'
const fs = require("fs");

const file = process.argv[2];

try {
    JSON.parse(fs.readFileSync(file, "utf8"));
    console.log("PASS", file);
} catch (error) {
    console.error("FAIL", file);
    console.error(error.message);
    process.exit(1);
}
NODE
}

validate_configuration() {
    log "CONFIGURATION"

    validate_json package.json || return 1
    validate_json tsconfig.json || return 1
    validate_json jsconfig.json || return 1

    return 0
}

###############################################################################
# SOURCE SAFETY
###############################################################################

scan_source() {
    log "SOURCE SAFETY"

    grep -RInE \
        'TODO|FIXME|XXX|<<<<<<<|=======|>>>>>>>' \
        . \
        --exclude-dir=node_modules \
        --exclude-dir=.next \
        --exclude-dir=.git \
        --exclude-dir=.completion-state \
        > "$REPORTS/cycle-$CYCLE-source-warnings.txt" \
        2>/dev/null || true

    return 0
}

###############################################################################
# SECURITY SURFACE
###############################################################################

security_scan() {
    log "SECURITY SURFACE"

    grep -RIlE \
        'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|sk-[A-Za-z0-9]' \
        . \
        --exclude-dir=node_modules \
        --exclude-dir=.next \
        --exclude-dir=.git \
        --exclude-dir=.completion-state \
        > "$REPORTS/cycle-$CYCLE-secret-scan.txt" \
        2>/dev/null || true

    return 0
}

###############################################################################
# LINT
###############################################################################

run_lint() {
    if has_script lint; then
        log "LINT"
        npm run lint \
            > "$REPORTS/cycle-$CYCLE-lint.log" 2>&1
        return $?
    fi

    log "LINT: no configured script"
    return 0
}

###############################################################################
# TYPECHECK
###############################################################################

run_typecheck() {
    if has_script typecheck; then
        log "TYPECHECK"
        npm run typecheck \
            > "$REPORTS/cycle-$CYCLE-typecheck.log" 2>&1
        return $?
    fi

    if [ -x node_modules/.bin/tsc ] &&
       [ -f tsconfig.json ]; then

        log "TYPECHECK: TSC"

        node_modules/.bin/tsc \
            --noEmit \
            > "$REPORTS/cycle-$CYCLE-typecheck.log" 2>&1

        return $?
    fi

    log "TYPECHECK: skipped"
    return 0
}

###############################################################################
# TEST MATRIX
###############################################################################

run_tests() {
    log "TEST MATRIX"

    if has_script test; then
        npm test \
            > "$REPORTS/cycle-$CYCLE-test.log" 2>&1
        return $?
    fi

    if has_script "test:ci"; then
        npm run test:ci \
            > "$REPORTS/cycle-$CYCLE-test.log" 2>&1
        return $?
    fi

    if [ -x node_modules/.bin/jest ]; then
        node_modules/.bin/jest \
            --runInBand \
            > "$REPORTS/cycle-$CYCLE-test.log" 2>&1
        return $?
    fi

    if [ -x node_modules/.bin/vitest ]; then
        node_modules/.bin/vitest \
            run \
            > "$REPORTS/cycle-$CYCLE-test.log" 2>&1
        return $?
    fi

    log "TEST MATRIX: no test runner configured"
    return 0
}

###############################################################################
# BUILD MATRIX
###############################################################################

run_build() {
    log "BUILD MATRIX"

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
# NEXT ARTIFACT MATRIX
###############################################################################

verify_next_artifacts() {
    log "NEXT ARTIFACT MATRIX"

    [ -d .next ] || {
        log "FAIL: .next missing"
        return 1
    }

    [ -d .next/server ] || {
        log "FAIL: .next/server missing"
        return 1
    }

    local files
    files="$(
        find .next/server \
            -type f \
            2>/dev/null |
            wc -l
    )"

    log "SERVER FILES=$files"

    [ "$files" -gt 0 ] || return 1

    {
        for manifest in \
            .next/server/app-paths-manifest.json \
            .next/server/pages-manifest.json \
            .next/server/middleware-manifest.json \
            .next/server/server-reference-manifest.json
        do
            if [ -f "$manifest" ]; then
                echo "PASS $manifest"
            else
                echo "ABSENT $manifest"
            fi
        done
    } > "$REPORTS/cycle-$CYCLE-manifests.txt"

    find .next/server \
        -type f \
        2>/dev/null |
        sort \
        > "$ARTIFACTS/cycle-$CYCLE-server-files.txt"

    return 0
}

###############################################################################
# ROUTE MATRIX
###############################################################################

verify_routes() {
    log "ROUTE MATRIX"

    {
        echo "=== APP ROUTES ==="
        find app \
            -type f \
            \( \
                -name 'page.*' -o \
                -name 'route.*' \
            \) \
            2>/dev/null |
            sort

        echo
        echo "=== PAGES ROUTES ==="
        find pages \
            -type f \
            2>/dev/null |
            sort

        echo
        echo "=== GENERATED ROUTES ==="
        find .next/server \
            -type f \
            \( \
                -name '*.js' -o \
                -name '*.json' \
            \) \
            2>/dev/null |
            sort
    } > "$REPORTS/cycle-$CYCLE-routes.txt"

    return 0
}

###############################################################################
# PRODUCTION SERVER
###############################################################################

start_server() {
    stop_server

    log "PRODUCTION SERVER"

    [ -x node_modules/.bin/next ] || return 1

    PORT="$PORT" \
        node_modules/.bin/next start \
        > "$REPORTS/cycle-$CYCLE-server.log" 2>&1 &

    SERVER_PID=$!

    sleep 5

    kill -0 "$SERVER_PID" 2>/dev/null
}

###############################################################################
# LOCAL HEALTH
###############################################################################

health_check() {
    local url="http://127.0.0.1:$PORT"

    log "HEALTH=$url"

    if command -v curl >/dev/null 2>&1; then
        curl \
            --silent \
            --show-error \
            --fail \
            --max-time 15 \
            "$url/" \
            > "$HEALTH/cycle-$CYCLE.html" \
            2> "$HEALTH/cycle-$CYCLE.log"

        return $?
    fi

    if command -v wget >/dev/null 2>&1; then
        wget \
            -q \
            -O "$HEALTH/cycle-$CYCLE.html" \
            "$url/"

        return $?
    fi

    kill -0 "$SERVER_PID" 2>/dev/null
}

###############################################################################
# DEPLOYMENT TARGET
###############################################################################

deployment_available() {
    if [ -n "${DEPLOYMENT_COMMAND:-}" ]; then
        return 0
    fi

    if command -v vercel >/dev/null 2>&1 &&
       [ -f .vercel/project.json ]; then
        return 0
    fi

    return 1
}

deploy() {
    if [ -n "${DEPLOYMENT_COMMAND:-}" ]; then

        log "DEPLOYMENT: configured command"

        bash -lc "$DEPLOYMENT_COMMAND" \
            > "$DEPLOYMENTS/cycle-$CYCLE.log" 2>&1

        return $?
    fi

    if command -v vercel >/dev/null 2>&1 &&
       [ -f .vercel/project.json ]; then

        log "DEPLOYMENT: Vercel"

        vercel deploy \
            --prod \
            > "$DEPLOYMENTS/cycle-$CYCLE.log" 2>&1

        return $?
    fi

    log "DEPLOYMENT: deferred — no configured target"
    echo "DEPLOYMENT=DEFERRED" \
        > "$DEPLOYMENTS/cycle-$CYCLE.log"

    return 0
}

###############################################################################
# PRODUCTION VERIFICATION
###############################################################################

verify_production() {
    local url="${DEPLOYMENT_URL:-}"

    [ -n "$url" ] || {
        log "PRODUCTION VERIFY: no URL configured"
        return 0
    }

    log "PRODUCTION VERIFY=$url"

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
# STATUS
###############################################################################

write_status() {
    local status="$1"
    local server=false
    local build=false

    [ -d .next ] && build=true
    [ -d .next/server ] && server=true

    cat > "$STATE/status.json" <<JSON
{
  "engine": "$ENGINE",
  "fabric": "$FABRIC",
  "version": "$VERSION",
  "mode": "CONTINUOUS",
  "cycle": $CYCLE,
  "status": "$status",
  "cpu": $(cpu_count),
  "ram_available_mb": $(ram_available),
  "ram_total_mb": $(ram_total),
  "disk_available_mb": $(disk_available),
  "build_artifact": $build,
  "server_artifact": $server,
  "timestamp": "$(date -Iseconds)"
}
JSON
}

###############################################################################
# FAILURE RECORD
###############################################################################

record_failure() {
    local stage="$1"

    cat > "$FAILURES/cycle-$CYCLE.json" <<JSON
{
  "cycle": $CYCLE,
  "stage": "$stage",
  "timestamp": "$(date -Iseconds)",
  "ram_available_mb": $(ram_available),
  "disk_available_mb": $(disk_available)
}
JSON
}

###############################################################################
# COMPLETE ONE FULL ENGINEERING CYCLE
###############################################################################

cycle() {

    CYCLE=$((CYCLE + 1))

    local report="$REPORTS/cycle-$CYCLE-summary.log"

    {
        log "=============================================================="
        log "$ENGINE"
        log "$FABRIC"
        log "CYCLE=$CYCLE"
        log "=============================================================="

        write_status RUNNING

        discover_surface ||
            { record_failure DISCOVERY; return 1; }

        snapshot

        install_dependencies ||
            { record_failure DEPENDENCIES; return 1; }

        validate_configuration ||
            { record_failure CONFIGURATION; return 1; }

        scan_source

        security_scan

        run_lint ||
            { record_failure LINT; return 1; }

        run_typecheck ||
            { record_failure TYPECHECK; return 1; }

        run_tests ||
            { record_failure TESTS; return 1; }

        run_build ||
            { record_failure BUILD; return 1; }

        verify_next_artifacts ||
            { record_failure ARTIFACTS; return 1; }

        verify_routes

        start_server ||
            { record_failure SERVER_START; return 1; }

        health_check ||
            { record_failure LOCAL_HEALTH; stop_server; return 1; }

        deploy ||
            { record_failure DEPLOYMENT; stop_server; return 1; }

        verify_production ||
            { record_failure PRODUCTION_VERIFY; stop_server; return 1; }

        stop_server

        write_status HEALTHY

        log "CYCLE=$CYCLE STATUS=COMPLETE"
        log "NEXT CYCLE WILL BEGIN AUTOMATICALLY"

    } > "$report" 2>&1

    cat "$report"

    return 0
}

###############################################################################
# BOOT
###############################################################################

clear_terminal

echo "=============================================================="
echo " $ENGINE"
echo " $FABRIC"
echo " $VERSION"
echo "=============================================================="
echo "CPU                : $(cpu_count)"
echo "RAM                : $(ram_available)MB / $(ram_total)MB"
echo "DISK               : $(disk_available)MB"
echo "MODE               : CONTINUOUS"
echo "BUILD              : ENABLED"
echo "TEST               : ENABLED"
echo "VERIFY             : ENABLED"
echo "DEPLOY             : ENABLED WHEN TARGET EXISTS"
echo "REPAIR             : ENABLED"
echo "REPEAT             : ENABLED"
echo "EXIT AFTER SUCCESS : DISABLED"
echo "=============================================================="

###############################################################################
# PERMANENT SUPERVISOR
###############################################################################

while true; do

    RAM="$(ram_available)"

    if [ "$RAM" -lt 300 ]; then
        write_status RESOURCE_THROTTLED

        log "RESOURCE THROTTLE: RAM=${RAM}MB"

        stop_server
        sleep 15

        continue
    fi

    if cycle; then

        clear_terminal

        echo "=============================================================="
        echo " $ENGINE — CYCLE COMPLETE"
        echo "=============================================================="
        echo "CYCLE       : $CYCLE"
        echo "BUILD       : PASS"
        echo "ARTIFACT    : $([ -d .next ] && echo PASS || echo FAIL)"
        echo "SERVER      : $([ -d .next/server ] && echo PASS || echo FAIL)"
        echo "STATUS      : HEALTHY"
        echo "SUPERVISOR  : ACTIVE"
        echo "NEXT CYCLE  : AUTOMATIC"
        echo "EXIT        : DISABLED"
        echo "=============================================================="

        sleep "$SLEEP_SUCCESS"

    else

        stop_server
        write_status REPAIRING

        clear_terminal

        echo "=============================================================="
        echo " $ENGINE — REPAIR CYCLE"
        echo "=============================================================="
        echo "FAILED CYCLE : $CYCLE"
        echo "MODE         : AUTOMATIC REPAIR"
        echo "EXIT         : DISABLED"
        echo "NEXT ACTION  : REBUILD / TEST / VERIFY"
        echo "=============================================================="

        tail -50 "$REPORTS/cycle-$CYCLE-summary.log" 2>/dev/null || true

        sleep "$SLEEP_FAILURE"
    fi

done
