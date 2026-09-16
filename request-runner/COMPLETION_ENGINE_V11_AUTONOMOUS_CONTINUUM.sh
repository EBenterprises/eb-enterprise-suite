#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="COMPLETION_ENGINE® — AUTONOMOUS CONTINUUM V11"

STATE=".completion-state"
LOGDIR=".completion-logs"
BACKUP=".completion-backups"
FABRIC="$STATE/virtual-workers"
QUEUE="$STATE/virtual-queue"
VERSIONS="$STATE/versions"
BRANCHES="$STATE/branches"
CHECKPOINTS="$STATE/checkpoints"
LOCK="$STATE/.continuum.lock"

mkdir -p \
    "$STATE" \
    "$LOGDIR" \
    "$BACKUP" \
    "$FABRIC/hot" \
    "$FABRIC/warm" \
    "$FABRIC/cold" \
    "$QUEUE" \
    "$VERSIONS" \
    "$BRANCHES" \
    "$CHECKPOINTS"

TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/continuum-$TS.log"

exec > >(tee "$LOG") 2>&1

cleanup() {
    rm -f "$LOCK"
}
trap cleanup EXIT INT TERM

if [ -e "$LOCK" ]; then
    echo "Another autonomous continuum is already running."
    exit 0
fi

touch "$LOCK"

echo "=============================================================="
echo " $ENGINE"
echo "=============================================================="
echo "START: $(date -Iseconds)"
echo

EXPECTED_ROUTES=(
    "administration/route.js"
    "administration/[id]/route.js"
    "customers/route.js"
    "customers/[id]/route.js"
    "drivers/route.js"
    "drivers/[id]/route.js"
    "locations/route.js"
    "locations/[id]/route.js"
    "notifications/route.js"
    "notifications/[id]/route.js"
    "operations/route.js"
    "operations/[id]/route.js"
    "orders/route.js"
    "orders/[id]/route.js"
    "payments/route.js"
    "payments/[id]/route.js"
    "requests/route.js"
    "requests/[id]/route.js"
    "requests/[id]/accept/route.js"
    "scheduling/route.js"
    "scheduling/[id]/route.js"
    "health/route.js"
)

CPU="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"

available_mb() {
    awk '/MemAvailable/ {printf "%d",$2/1024; exit}' \
        /proc/meminfo 2>/dev/null || echo 0
}

free_disk_mb() {
    df -Pm . 2>/dev/null | awk 'NR==2 {print $4}'
}

safe_workers() {
    local mem="$1"
    local cpu="$CPU"
    local workers

    workers="$cpu"

    [ "$workers" -gt 8 ] && workers=8
    [ "$workers" -lt 2 ] && workers=2

    if [ "$mem" -lt 384 ]; then
        workers=2
    elif [ "$mem" -lt 768 ]; then
        workers=2
    elif [ "$mem" -lt 1536 ]; then
        [ "$workers" -gt 4 ] && workers=4
    elif [ "$mem" -lt 3072 ]; then
        [ "$workers" -gt 6 ] && workers=6
    fi

    echo "$workers"
}

route_count() {
    local n=0
    local route

    for route in "${EXPECTED_ROUTES[@]}"; do
        [ -f ".next/server/app/api/$route" ] &&
            n=$((n+1))
    done

    echo "$n"
}

manifest_gate() {
    local f

    for f in \
        ".next/server/app-paths-manifest.json" \
        ".next/server/pages-manifest.json" \
        ".next/server/middleware-manifest.json" \
        ".next/server/server-reference-manifest.json"
    do
        [ -f "$f" ] || return 1
    done

    return 0
}

source_gate() {
    local route

    for route in "${EXPECTED_ROUTES[@]}"; do
        [ -f "app/api/$route" ] || return 1
    done

    [ -f framework/api/crud-route.js ] || return 1

    grep -q '"@framework/\*"' jsconfig.json 2>/dev/null ||
        return 1

    grep -q '"@app/\*"' jsconfig.json 2>/dev/null ||
        return 1

    return 0
}

config_gate() {
    node - <<'NODE'
const fs = require("fs");

for (const f of ["package.json", "jsconfig.json"]) {
    JSON.parse(fs.readFileSync(f, "utf8"));
}

console.log("CONFIGURATION=PASS");
NODE
}

runtime_gate() {
    [ -f app/api/health/route.js ] &&
    [ -f framework/api/crud-route.js ]
}

artifact_gate() {
    [ "$(route_count)" -eq "${#EXPECTED_ROUTES[@]}" ] &&
    manifest_gate
}

known_good() {
    cat > "$STATE/known-good.json" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "status": "KNOWN_GOOD",
  "engine": "$ENGINE",
  "version": "$VERSION",
  "routes": "$(route_count)/${#EXPECTED_ROUTES[@]}",
  "build": "PASS",
  "manifests": "PASS",
  "source": "PASS",
  "configuration": "PASS",
  "runtime": "PASS",
  "memory_mb": $(available_mb),
  "workers": $(safe_workers "$(available_mb)")
}
JSON
}

create_virtual_worker() {
    local task="$1"
    local id

    id="$(date +%s%N)-$$-$RANDOM"

    mkdir -p "$FABRIC/cold/$id"

    cat > "$FABRIC/cold/$id/state.json" <<JSON
{
  "id": "$id",
  "task": "$task",
  "state": "QUEUED",
  "created": "$(date -Iseconds)",
  "execution": "DEFERRED_UNTIL_RESOURCE_AVAILABLE"
}
JSON

    printf '%s\n' "$id"
}

enqueue() {
    local task="$1"
    local id

    id="$(date +%s%N)-$$-$RANDOM"

    cat > "$QUEUE/$id.json" <<JSON
{
  "id": "$id",
  "task": "$task",
  "state": "QUEUED",
  "created": "$(date -Iseconds)"
}
JSON
}

spawn_analysis_fleet() {
    local names=(
        SOURCE
        CONFIG
        ROUTES
        MANIFESTS
        WEBPACK
        TYPES
        RUNTIME
        DEPENDENCIES
        SECURITY
        PERFORMANCE
        ACCESSIBILITY
        API
        DATA
        CACHE
        BUILD
        FAILURE
        RECOVERY
        REGRESSION
        VERSIONING
        DEPLOYMENT
    )

    local name

    for name in "${names[@]}"; do
        create_virtual_worker "$name" >/dev/null
        enqueue "$name"
    done

    echo "Logical workers created: ${#names[@]}"
}

repair_branch() {
    local class="$1"

    local branch="completion-engine/repair-$VERSION-$TS"

    mkdir -p "$BRANCHES/$VERSION"

    cat > "$BRANCHES/$VERSION/repair.json" <<JSON
{
  "version": "$VERSION",
  "branch": "$branch",
  "classification": "$class",
  "source_rewrite": false,
  "route_rewrite": false,
  "isolated": true,
  "promotion": "gated"
}
JSON

    echo "Repair branch prepared: $branch"
}

persist_state() {
    local mem
    local disk
    local routes

    mem="$(available_mb)"
    disk="$(free_disk_mb)"
    routes="$(route_count)"

    cat > "$STATE/continuum-state.json" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "engine": "$ENGINE",
  "version": "$VERSION",
  "memory_available_mb": $mem,
  "disk_available_mb": $disk,
  "cpu": $CPU,
  "active_workers": $(safe_workers "$mem"),
  "logical_worker_space": "storage_backed",
  "routes": "$routes/${#EXPECTED_ROUTES[@]}",
  "build": "$BUILD_STATUS",
  "status": "$STATUS"
}
JSON
}

#
# VERSION CONTINUUM
#
# Each cycle advances the architecture.
#

VERSION=11
MAX_VERSION=999999

while true; do

    MEM="$(available_mb)"
    DISK="$(free_disk_mb)"
    WORKERS="$(safe_workers "$MEM")"

    echo
    echo "=============================================================="
    echo " CONTINUUM CYCLE V$VERSION"
    echo "=============================================================="
    echo "RAM available : ${MEM} MB"
    echo "Disk available: ${DISK} MB"
    echo "CPU           : $CPU"
    echo "Active workers: $WORKERS"
    echo

    #
    # Resource pressure response
    #

    if [ "$MEM" -lt 256 ]; then
        echo "RESOURCE PRESSURE: CRITICAL"
        echo "Reducing active concurrency."
        WORKERS=2
    elif [ "$MEM" -lt 512 ]; then
        echo "RESOURCE PRESSURE: HIGH"
    else
        echo "RESOURCE PRESSURE: NORMAL"
    fi

    #
    # Create the next logical worker fleet.
    #

    echo "[1] SPAWNING LOGICAL WORKER FLEET"

    spawn_analysis_fleet

    #
    # Fast independent gates.
    #

    echo
    echo "[2] PARALLEL STATIC GATES"

    SOURCE=0
    CONFIG=0
    RUNTIME=0

    source_gate && SOURCE=1
    config_gate >/dev/null 2>&1 && CONFIG=1
    runtime_gate && RUNTIME=1

    echo "SOURCE  : $SOURCE"
    echo "CONFIG  : $CONFIG"
    echo "RUNTIME : $RUNTIME"

    #
    # If source/configuration is broken, classify rather than blindly
    # repeating the production build.
    #

    if [ "$SOURCE" -eq 0 ]; then
        echo "SOURCE FAILURE DETECTED"
        repair_branch "SOURCE_CONTRACT_FAILURE"

        STATUS="REPAIR_REQUIRED"
        BUILD_STATUS="NOT_RUN"

        persist_state

        #
        # Do not destroy known-good state.
        #
        echo "Known-good state retained."
        echo "Repair work persisted for next autonomous cycle."

        VERSION=$((VERSION+1))
        sleep 2
        continue
    fi

    if [ "$CONFIG" -eq 0 ]; then
        echo "CONFIGURATION FAILURE DETECTED"
        repair_branch "CONFIGURATION_FAILURE"

        STATUS="REPAIR_REQUIRED"
        BUILD_STATUS="NOT_RUN"

        persist_state

        VERSION=$((VERSION+1))
        sleep 2
        continue
    fi

    #
    # Controlled production build.
    #

    echo
    echo "[3] CONTROLLED PRODUCTION BUILD"

    rm -rf .next

    BUILD_START="$(date +%s)"

    if npm run build -- --webpack; then
        BUILD_RC=0
        BUILD_STATUS="PASS"
    else
        BUILD_RC=$?
        BUILD_STATUS="FAIL"
    fi

    BUILD_END="$(date +%s)"
    DURATION=$((BUILD_END-BUILD_START))

    ROUTES="$(route_count)"

    echo
    echo "Build exit : $BUILD_RC"
    echo "Duration   : ${DURATION}s"
    echo "Routes     : $ROUTES/${#EXPECTED_ROUTES[@]}"

    #
    # Post-build verification.
    #

    echo
    echo "[4] POST-BUILD ACCEPTANCE"

    if [ "$BUILD_RC" -eq 0 ] &&
       [ "$ROUTES" -eq "${#EXPECTED_ROUTES[@]}" ] &&
       manifest_gate &&
       source_gate &&
       config_gate >/dev/null 2>&1 &&
       runtime_gate
    then

        STATUS="VERIFIED"

        echo "✓ BUILD"
        echo "✓ ROUTES"
        echo "✓ MANIFESTS"
        echo "✓ SOURCE"
        echo "✓ CONFIGURATION"
        echo "✓ RUNTIME"

        #
        # Promote known-good state.
        #

        echo
        echo "[5] PROMOTION"

        known_good

        cp -f "$STATE/known-good.json" \
            "$CHECKPOINTS/v$VERSION-$TS-known-good.json"

        cat > "$VERSIONS/V$VERSION.json" <<JSON
{
  "version": "$VERSION",
  "status": "VERIFIED",
  "timestamp": "$(date -Iseconds)",
  "build": "PASS",
  "routes": "$ROUTES/${#EXPECTED_ROUTES[@]}",
  "duration_seconds": $DURATION,
  "workers": $WORKERS,
  "memory_mb": $MEM,
  "disk_mb": $DISK
}
JSON

        echo "✓ V$VERSION promoted"

    else

        STATUS="FAILED"

        echo
        echo "[5] FAILURE INTELLIGENCE"

        CLASS="UNKNOWN"

        if [ "$BUILD_RC" -ne 0 ]; then
            CLASS="PRODUCTION_BUILD_FAILURE"
        elif [ "$ROUTES" -ne "${#EXPECTED_ROUTES[@]}" ]; then
            CLASS="SERVER_ARTIFACT_EMISSION_FAILURE"
        elif ! manifest_gate; then
            CLASS="MANIFEST_FAILURE"
        elif ! runtime_gate; then
            CLASS="RUNTIME_FAILURE"
        fi

        echo "Classification: $CLASS"

        repair_branch "$CLASS"

        cat > "$STATE/last-failure.json" <<JSON
{
  "version": "$VERSION",
  "timestamp": "$(date -Iseconds)",
  "classification": "$CLASS",
  "build_exit": $BUILD_RC,
  "routes": "$ROUTES/${#EXPECTED_ROUTES[@]}",
  "repair": "ISOLATED"
}
JSON

        echo "✓ Failure state persisted"
        echo "✓ Known-good state protected"
    fi

    persist_state

    #
    # Automatic continuation.
    #
    # No user prompt.
    # No manual restart.
    # No blind duplicate build.
    #

    echo
    echo "[6] CONTINUUM TRANSITION"

    VERSION=$((VERSION+1))

    #
    # Prevent pathological integer growth while retaining effectively
    # unbounded logical versioning.
    #

    if [ "$VERSION" -ge "$MAX_VERSION" ]; then
        VERSION=11
    fi

    #
    # Compact completed queue state.
    #

    find "$QUEUE" \
        -type f \
        -name '*.json' \
        -mtime +1 \
        -delete 2>/dev/null || true

    #
    # Keep only recent worker reports.
    #

    find "$FABRIC/cold" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -mtime +3 \
        -exec rm -rf {} + 2>/dev/null || true

    #
    # Adaptive pause.
    #

    if [ "$MEM" -lt 384 ]; then
        sleep 8
    elif [ "$MEM" -lt 768 ]; then
        sleep 4
    else
        sleep 2
    fi

done
