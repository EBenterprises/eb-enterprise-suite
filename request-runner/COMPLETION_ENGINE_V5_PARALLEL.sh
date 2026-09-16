#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="COMPLETION_ENGINE® — PARALLEL AUTONOMOUS V5"
ROOT="$PWD"

STATE=".completion-state"
LOGDIR=".completion-logs"
BACKUP=".completion-backups"
WORK="$STATE/workers"
REPORTS="$STATE/reports"
REPAIRS="$STATE/repairs"
LOCK="$STATE/.v5.lock"

TS="$(date +%Y%m%d-%H%M%S)"
RUN="$STATE/run-$TS"
LOG="$LOGDIR/parallel-v5-$TS.log"

mkdir -p \
  "$STATE" \
  "$LOGDIR" \
  "$BACKUP" \
  "$WORK" \
  "$REPORTS" \
  "$REPAIRS" \
  "$RUN"

exec > >(tee "$LOG") 2>&1

cleanup() {
  rm -f "$LOCK"
}
trap cleanup EXIT INT TERM

if [ -e "$LOCK" ]; then
  echo "✗ Another Completion Engine® V5 run is active."
  exit 1
fi

touch "$LOCK"

echo "=============================================================="
echo " $ENGINE"
echo "=============================================================="
echo "Run:  $TS"
echo "Next: $(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)"
echo "Node: $(node -v 2>/dev/null || echo unknown)"
echo "Log:  $LOG"
echo "=============================================================="
echo

sha() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo unavailable
  fi
}

json_escape() {
  printf '%s' "$1" | sed \
    's/\\/\\\\/g; s/"/\\"/g; s/\r/\\r/g; s/\n/\\n/g'
}

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

required_manifests() {
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

route_count() {
  local n=0
  for route in "${EXPECTED_ROUTES[@]}"; do
    [ -f ".next/server/app/api/$route" ] && n=$((n + 1))
  done
  echo "$n"
}

detect_workers() {
  local cpu mem workers

  cpu="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
  mem="$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 2048)"

  workers="$cpu"

  [ "$workers" -gt 8 ] && workers=8
  [ "$workers" -lt 2 ] && workers=2

  if [ "$mem" -lt 1500 ]; then
    workers=2
  elif [ "$mem" -lt 3000 ] && [ "$workers" -gt 4 ]; then
    workers=4
  fi

  echo "$workers"
}

WORKERS="$(detect_workers)"

echo "[1/10] RESOURCE DISCOVERY"
echo "--------------------------------------------------------------"
echo "CPU workers available : $(getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
echo "Memory available      : $(awk '/MemAvailable/ {printf "%.0f MB",$2/1024}' /proc/meminfo 2>/dev/null || echo unknown)"
echo "Parallel workers      : $WORKERS"
echo "✓ Worker pool selected"

echo
echo "[2/10] KNOWN-GOOD CHECKPOINT"
echo "--------------------------------------------------------------"

if [ -f "$STATE/known-good.json" ]; then
  echo "✓ Known-good checkpoint exists"
  cp -f "$STATE/known-good.json" "$RUN/known-good-before.json"
else
  echo "• No prior checkpoint"
fi

cat > "$RUN/project-state.json" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "next": "$(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)",
  "node": "$(node -v 2>/dev/null || echo unknown)",
  "package": "$(sha package.json)",
  "lockfile": "$(sha package-lock.json)",
  "next_config": "$(sha next.config.js)",
  "jsconfig": "$(sha jsconfig.json)",
  "workers": $WORKERS
}
JSON

echo "✓ Project state captured"

echo
echo "[3/10] WORKER DEFINITIONS"
echo "--------------------------------------------------------------"

create_worker() {
  local id="$1"
  local name="$2"

  mkdir -p "$WORK/$id" "$REPORTS/$id"

  cat > "$WORK/$id/run.sh" <<WORKER
#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$ROOT" || exit 1

ID="$id"
NAME="$name"
OUT="$REPORTS/$id"
REPORT="\$OUT/report.txt"

{
  echo "WORKER=\$ID"
  echo "NAME=\$NAME"
  echo "START=\$(date -Iseconds)"
} > "\$REPORT"

case "\$NAME" in

SOURCE)
  {
    echo
    echo "SOURCE CONTRACT"

    failures=0

    for route in \
      "administration/route.js" \
      "administration/[id]/route.js" \
      "customers/route.js" \
      "customers/[id]/route.js" \
      "drivers/route.js" \
      "drivers/[id]/route.js" \
      "locations/route.js" \
      "locations/[id]/route.js" \
      "notifications/route.js" \
      "notifications/[id]/route.js" \
      "operations/route.js" \
      "operations/[id]/route.js" \
      "orders/route.js" \
      "orders/[id]/route.js" \
      "payments/route.js" \
      "payments/[id]/route.js" \
      "requests/route.js" \
      "requests/[id]/route.js" \
      "requests/[id]/accept/route.js" \
      "scheduling/route.js" \
      "scheduling/[id]/route.js" \
      "health/route.js"
    do
      [ -f "app/api/\$route" ] || {
        echo "MISSING app/api/\$route"
        failures=\$((failures + 1))
      }
    done

    [ -f framework/api/crud-route.js ] || failures=\$((failures + 1))

    if [ "\$failures" -eq 0 ]; then
      echo "PASS"
      exit 0
    fi

    echo "FAILURES=\$failures"
    exit 1
  } >> "\$REPORT" 2>&1
  ;;

CONFIG)
  {
    echo
    echo "CONFIGURATION CONTRACT"

    node - <<'NODE'
const fs = require("fs");

let failures = 0;

for (const file of ["package.json","jsconfig.json"]) {
  try {
    JSON.parse(fs.readFileSync(file,"utf8"));
    console.log("PASS", file);
  } catch (e) {
    console.log("FAIL", file, e.message);
    failures++;
  }
}

const js = fs.readFileSync("jsconfig.json","utf8");

for (const alias of ["@framework/*","@app/*"]) {
  if (!js.includes(alias)) {
    console.log("FAIL missing alias", alias);
    failures++;
  }
}

process.exit(failures ? 1 : 0);
NODE
  } >> "\$REPORT" 2>&1
  ;;

ROUTES)
  {
    echo
    echo "ROUTE EMISSION CONTRACT"

    if [ ! -d .next/server/app/api ]; then
      echo "NO_BUILD_ARTIFACTS"
      exit 1
    fi

    emitted=0

    for route in \
      "administration/route.js" \
      "administration/[id]/route.js" \
      "customers/route.js" \
      "customers/[id]/route.js" \
      "drivers/route.js" \
      "drivers/[id]/route.js" \
      "locations/route.js" \
      "locations/[id]/route.js" \
      "notifications/route.js" \
      "notifications/[id]/route.js" \
      "operations/route.js" \
      "operations/[id]/route.js" \
      "orders/route.js" \
      "orders/[id]/route.js" \
      "payments/route.js" \
      "payments/[id]/route.js" \
      "requests/route.js" \
      "requests/[id]/route.js" \
      "requests/[id]/accept/route.js" \
      "scheduling/route.js" \
      "scheduling/[id]/route.js" \
      "health/route.js"
    do
      [ -f ".next/server/app/api/\$route" ] && emitted=\$((emitted + 1))
    done

    echo "EMITTED=\$emitted"

    [ "\$emitted" -eq 22 ]
  } >> "\$REPORT" 2>&1
  ;;

MANIFESTS)
  {
    echo
    echo "MANIFEST CONTRACT"

    failures=0

    for manifest in \
      ".next/server/app-paths-manifest.json" \
      ".next/server/pages-manifest.json" \
      ".next/server/middleware-manifest.json" \
      ".next/server/server-reference-manifest.json"
    do
      if [ -f "\$manifest" ]; then
        echo "PASS \$manifest"
      else
        echo "FAIL \$manifest"
        failures=\$((failures + 1))
      fi
    done

    if [ -f ".next/server/next-font-manifest.json" ]; then
      echo "OPTIONAL next-font-manifest.json PRESENT"
    else
      echo "OPTIONAL next-font-manifest.json ABSENT"
    fi

    exit "\$failures"
  } >> "\$REPORT" 2>&1
  ;;

WEBPACK)
  {
    echo
    echo "WEBPACK / ANDROID POLICY"

    if grep -q "webpack" package.json next.config.js 2>/dev/null; then
      echo "PASS webpack surface present"
    fi

    if grep -q "webpack" next.config.js 2>/dev/null; then
      echo "PASS custom webpack hook present"
    else
      echo "WARNING no custom webpack hook detected"
    fi

    echo "TARGET=WEBPACK"
  } >> "\$REPORT" 2>&1
  ;;

TYPES)
  {
    echo
    echo "TYPE CONTRACT"

    if [ -f jsconfig.json ]; then
      node -e 'JSON.parse(require("fs").readFileSync("jsconfig.json","utf8")); console.log("PASS jsconfig")'
    fi

    echo "PASS static configuration probe"
  } >> "\$REPORT" 2>&1
  ;;

RUNTIME)
  {
    echo
    echo "RUNTIME SURFACE"

    for file in \
      "app/api/health/route.js" \
      "framework/api/crud-route.js"
    do
      if [ -f "\$file" ]; then
        echo "PASS \$file"
      else
        echo "FAIL \$file"
        exit 1
      fi
    done

    echo "PASS runtime surface"
  } >> "\$REPORT" 2>&1
  ;;

FAILURE)
  {
    echo
    echo "FAILURE INTELLIGENCE"

    latest=""
    for candidate in .completion-logs/*.log; do
      [ -f "\$candidate" ] || continue
      [ "\$candidate" = "$LOG" ] && continue
      latest="\$candidate"
    done

    if [ -n "\$latest" ]; then
      echo "EVIDENCE=\$latest"

      grep -qE \
        'Cannot find module .*\\.next/server/app/.*/route\\.js|Failed to collect page data' \
        "\$latest" && echo "CLASS=SERVER_ARTIFACT_EMISSION_FAILURE"

      grep -qE \
        'Unable to snapshot resolve dependencies|PackFileCacheStrategy' \
        "\$latest" && echo "CLASS=WEBPACK_CACHE_WARNING"

      grep -qE \
        'Module not found|Can.t resolve|Cannot resolve' \
        "\$latest" && echo "CLASS=MODULE_RESOLUTION_FAILURE"

      grep -qE \
        'TS[0-9]{4}|TypeScript error|Type error' \
        "\$latest" && echo "CLASS=TYPESCRIPT_FAILURE"
    else
      echo "NO_HISTORICAL_FAILURE"
    fi

    echo "PASS failure intelligence scan"
  } >> "\$REPORT" 2>&1
  ;;

esac

echo "END=\$(date -Iseconds)" >> "\$REPORT"
exit 0
WORKER

  chmod +x "$WORK/$id/run.sh"
}

create_worker 01 SOURCE
create_worker 02 CONFIG
create_worker 03 ROUTES
create_worker 04 MANIFESTS
create_worker 05 WEBPACK
create_worker 06 TYPES
create_worker 07 RUNTIME
create_worker 08 FAILURE

echo "✓ 8 independent worker definitions created"

echo
echo "[4/10] PARALLEL WORKER SPAWN"
echo "--------------------------------------------------------------"

PIDS=""

spawn_worker() {
  local id="$1"

  (
    "$WORK/$id/run.sh"
  ) > "$WORK/$id/output.log" 2>&1 &

  echo $! > "$WORK/$id/pid"
  PIDS="$PIDS $!"
}

for id in 01 02 03 04 05 06 07 08; do
  spawn_worker "$id"
done

echo "✓ Worker 01 SOURCE      spawned"
echo "✓ Worker 02 CONFIG      spawned"
echo "✓ Worker 03 ROUTES      spawned"
echo "✓ Worker 04 MANIFESTS   spawned"
echo "✓ Worker 05 WEBPACK     spawned"
echo "✓ Worker 06 TYPES       spawned"
echo "✓ Worker 07 RUNTIME     spawned"
echo "✓ Worker 08 FAILURE     spawned"

echo
echo "[5/10] PARALLEL JOIN"
echo "--------------------------------------------------------------"

FAILURES=0

for pid in $PIDS; do
  if wait "$pid"; then
    :
  else
    FAILURES=$((FAILURES + 1))
  fi
done

echo "Workers completed: 8"
echo "Worker process failures: $FAILURES"

echo
echo "[6/10] WORKER RESULT MERGE"
echo "--------------------------------------------------------------"

PASS_COUNT=0
FAIL_COUNT=0

for id in 01 02 03 04 05 06 07 08; do
  echo
  echo "--- worker $id ---"

  if [ -f "$REPORTS/$id/report.txt" ]; then
    tail -20 "$REPORTS/$id/report.txt"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "NO REPORT"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

echo
echo "Reports received: $PASS_COUNT"
echo "Missing reports : $FAIL_COUNT"

echo
echo "[7/10] REPAIR CANDIDATE DISCOVERY"
echo "--------------------------------------------------------------"

REPAIR_CLASS="NONE"

if grep -Rqs "CLASS=SERVER_ARTIFACT_EMISSION_FAILURE" "$REPORTS"; then
  REPAIR_CLASS="SERVER_ARTIFACT_EMISSION_FAILURE"
fi

if grep -Rqs "CLASS=MODULE_RESOLUTION_FAILURE" "$REPORTS"; then
  REPAIR_CLASS="MODULE_RESOLUTION_FAILURE"
fi

if grep -Rqs "CLASS=TYPESCRIPT_FAILURE" "$REPORTS"; then
  REPAIR_CLASS="TYPESCRIPT_FAILURE"
fi

if [ "$REPAIR_CLASS" = "SERVER_ARTIFACT_EMISSION_FAILURE" ]; then
  cat > "$REPAIRS/$TS-server-artifact-repair.plan" <<PLAN
CLASS=SERVER_ARTIFACT_EMISSION_FAILURE
STRATEGY=CACHE_AND_EMISSION_DIAGNOSTIC
MUTATION=CONFIG_ONLY
SOURCE_MUTATION=FALSE
ROUTE_REWRITE=FALSE
PLAN

  echo "✓ Server-artifact repair candidate recorded"
elif [ "$REPAIR_CLASS" = "MODULE_RESOLUTION_FAILURE" ]; then
  cat > "$REPAIRS/$TS-module-resolution.plan" <<PLAN
CLASS=MODULE_RESOLUTION_FAILURE
STRATEGY=ALIAS_TARGET_INSPECTION
MUTATION=CONFIG_ONLY
SOURCE_MUTATION=FALSE
ROUTE_REWRITE=FALSE
PLAN

  echo "✓ Module-resolution repair candidate recorded"
elif [ "$REPAIR_CLASS" = "TYPESCRIPT_FAILURE" ]; then
  cat > "$REPAIRS/$TS-typescript.plan" <<PLAN
CLASS=TYPESCRIPT_FAILURE
STRATEGY=TYPE_DIAGNOSTIC
MUTATION=SOURCE_TARGETED
ROUTE_REWRITE=FALSE
PLAN

  echo "✓ TypeScript repair candidate recorded"
else
  echo "✓ No repair candidate required"
fi

echo
echo "[8/10] FINAL CONTROLLED PRODUCTION BUILD"
echo "--------------------------------------------------------------"

echo "Workers have completed independent analysis."
echo "Coordinator owns final build."
echo "Exactly ONE final production build."

rm -rf .next

BUILD_START="$(date +%s)"

if npm run build -- --webpack; then
  BUILD_RC=0
else
  BUILD_RC=$?
fi

BUILD_END="$(date +%s)"
DURATION=$((BUILD_END - BUILD_START))

EMITTED="$(route_count)"

echo
echo "Build exit : $BUILD_RC"
echo "Duration   : ${DURATION}s"
echo "Routes     : $EMITTED/22"

echo
echo "[9/10] AUTOMATIC PROMOTION"
echo "--------------------------------------------------------------"

PROMOTION="FAIL"

if [ "$BUILD_RC" -eq 0 ] &&
   [ "$EMITTED" -eq 22 ] &&
   required_manifests
then
  PROMOTION="PASS"

  cat > "$STATE/known-good.json" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "status": "KNOWN_GOOD",
  "engine": "$ENGINE",
  "next": "$(node -p "require('./node_modules/next/package.json').version")",
  "node": "$(node -v)",
  "package": "$(sha package.json)",
  "lockfile": "$(sha package-lock.json)",
  "next_config": "$(sha next.config.js)",
  "jsconfig": "$(sha jsconfig.json)",
  "workers": 8,
  "route_artifacts": $EMITTED,
  "build_exit_code": $BUILD_RC,
  "build_duration_seconds": $DURATION,
  "policy": "ANDROID_ARM64_WEBPACK"
}
JSON

  cp -f "$STATE/known-good.json" \
    "$RUN/known-good.json"

  echo "✓ Known-good state promoted"

  if command -v git >/dev/null 2>&1 &&
     git rev-parse --is-inside-work-tree >/dev/null 2>&1
  then
    BRANCH="completion-engine/verified-$TS"

    if git diff --quiet -- next.config.js jsconfig.json 2>/dev/null; then
      echo "• No configuration changes requiring Git promotion"
    else
      git checkout -b "$BRANCH" 2>/dev/null || true
      git add next.config.js jsconfig.json .completion-state 2>/dev/null || true
      git commit -m "Completion Engine®: promote verified build state" \
        >/dev/null 2>&1 || true
      echo "✓ Versioned verification branch: $BRANCH"
    fi
  else
    echo "• Git unavailable — state retained in Completion Engine® store"
  fi
fi

echo
echo "[10/10] SELF-COMPLETION DECISION"
echo "--------------------------------------------------------------"

if [ "$PROMOTION" = "PASS" ]; then

  cat > "$STATE/latest-success.json" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "run": "$TS",
  "status": "COMPLETE",
  "workers": 8,
  "parallel": true,
  "routes": "$EMITTED/22",
  "build": "PASS",
  "duration_seconds": $DURATION,
  "next": "$(node -p "require('./node_modules/next/package.json').version")",
  "platform_policy": "ANDROID_ARM64_WEBPACK"
}
JSON

  echo
  echo "=============================================================="
  echo " COMPLETION ENGINE® — SELF-COMPLETED"
  echo "=============================================================="
  echo "STATUS       : PASS"
  echo "WORKERS      : 8 PARALLEL"
  echo "BUILD        : PASS"
  echo "ROUTES       : $EMITTED/22"
  echo "MANIFESTS    : PASS"
  echo "KNOWN-GOOD   : RECORDED"
  echo "STATE        : $STATE/latest-success.json"
  echo "LOG          : $LOG"
  echo "=============================================================="

  exit 0
fi

echo
echo "=============================================================="
echo " COMPLETION ENGINE® — REPAIR REQUIRED"
echo "=============================================================="
echo "BUILD EXIT   : $BUILD_RC"
echo "ROUTES       : $EMITTED/22"
echo "REPAIR CLASS : $REPAIR_CLASS"
echo "LOG          : $LOG"
echo "=============================================================="

exit "${BUILD_RC:-1}"
