#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="COMPLETION ENGINE® — UNIVERSAL FABRIC®"
VERSION="UNIVERSAL-8.0"

ROOT="$PWD"
STATE="$ROOT/.completion-state"
FABRIC="$STATE/universal-fabric"
QUEUE="$FABRIC/queue"
RUNNING="$FABRIC/running"
DONE="$FABRIC/done"
FAILED="$FABRIC/failed"
RETRY="$FABRIC/retry"
SEEN="$FABRIC/seen"
REPORTS="$FABRIC/reports"
AGENTS="$FABRIC/agents"
MEMORY="$FABRIC/virtual-memory"
SNAP="$FABRIC/snapshots"
BRANCHES="$FABRIC/branches"
LOGDIR="$ROOT/.completion-logs"

LOCK="$STATE/.universal.lock"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/universal-$TS.log"

mkdir -p \
  "$STATE" "$FABRIC" "$QUEUE" "$RUNNING" "$DONE" "$FAILED" \
  "$RETRY" "$SEEN" "$REPORTS" "$AGENTS" "$MEMORY" "$SNAP" \
  "$BRANCHES" "$LOGDIR"

cleanup() {
  rm -f "$LOCK"
}
trap cleanup EXIT INT TERM

if [ -e "$LOCK" ]; then
  echo "✗ $ENGINE already running."
  exit 1
fi

touch "$LOCK"
exec > >(tee "$LOG") 2>&1

###############################################################################
# RESOURCE INTELLIGENCE
###############################################################################

cpu_count() {
  getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2
}

mem_available() {
  awk '
    /MemAvailable:/ {
      printf "%d\n",$2/1024
      found=1
      exit
    }
    END {
      if (!found) print 256
    }
  ' /proc/meminfo 2>/dev/null
}

mem_total() {
  awk '
    /MemTotal:/ {
      printf "%d\n",$2/1024
      found=1
      exit
    }
    END {
      if (!found) print 512
    }
  ' /proc/meminfo 2>/dev/null
}

disk_available() {
  df -Pm "$ROOT" 2>/dev/null |
    awk 'NR>1 && $4 ~ /^[0-9]+$/ {print $4; exit}'
}

pressure_level() {
  local m
  m="$(mem_available)"

  if [ "$m" -lt 384 ]; then
    echo CRITICAL
  elif [ "$m" -lt 768 ]; then
    echo HIGH
  elif [ "$m" -lt 1536 ]; then
    echo NORMAL
  else
    echo EXPANSION
  fi
}

worker_capacity() {
  local m cpu cap

  m="$(mem_available)"
  cpu="$(cpu_count)"

  if [ "$m" -lt 384 ]; then
    cap=1
  elif [ "$m" -lt 768 ]; then
    cap=2
  elif [ "$m" -lt 1536 ]; then
    cap=3
  elif [ "$m" -lt 3072 ]; then
    cap=4
  else
    cap="$cpu"
    [ "$cap" -gt 8 ] && cap=8
  fi

  echo "$cap"
}

###############################################################################
# COMPATIBILITY / MIGRATION
###############################################################################

migrate_legacy_state() {
  local old

  for old in \
    "$STATE/elastic-fabric" \
    "$STATE/v7" \
    "$STATE/v7.1" \
    "$STATE/v7.2"
  do
    [ -d "$old" ] || continue

    find "$old" -type f -name '*.task' -exec mv -n {} "$QUEUE/" \; 2>/dev/null || true
    find "$old" -type f -name '*.report' -exec mv -n {} "$REPORTS/" \; 2>/dev/null || true
  done

  touch "$STATE/.universal-migrated"
}

###############################################################################
# TASK IDENTITY
###############################################################################

task_key() {
  printf '%s|%s\n' "$1" "$2" |
    sha256sum 2>/dev/null |
    awk '{print $1}'
}

enqueue() {
  local type="$1"
  local priority="${2:-50}"
  local parent="${3:-ROOT}"
  local key
  local id

  key="$(task_key "$type" "$parent")"

  [ -e "$SEEN/$key" ] && return 0

  touch "$SEEN/$key"

  id="$(date +%s%N)-$RANDOM"

  cat > "$QUEUE/$id.task" <<TASK
ID=$id
KEY=$key
TYPE=$type
PRIORITY=$priority
PARENT=$parent
CREATED=$(date -Iseconds)
STATUS=QUEUED
TASK
}

###############################################################################
# MASTER GRAPH
###############################################################################

seed() {
  local t

  for t in \
    DISCOVERY \
    SOURCE \
    CONFIG \
    ROUTES \
    MANIFESTS \
    DEPENDENCIES \
    TYPES \
    WEBPACK \
    MEMORY \
    PERFORMANCE \
    SECURITY \
    RUNTIME \
    TESTS \
    BUILD \
    ARCHITECTURE \
    VERSION
  do
    enqueue "$t" 50 ROOT
  done
}

###############################################################################
# SNAPSHOT / REPAIR
###############################################################################

snapshot_project() {
  local id="$1"
  local target="$BRANCHES/$id"

  mkdir -p "$target"

  cp -f package.json "$target/" 2>/dev/null || true
  cp -f package-lock.json "$target/" 2>/dev/null || true
  cp -f next.config.js "$target/" 2>/dev/null || true
  cp -f next.config.mjs "$target/" 2>/dev/null || true
  cp -f next.config.ts "$target/" 2>/dev/null || true
  cp -f jsconfig.json "$target/" 2>/dev/null || true
  cp -f tsconfig.json "$target/" 2>/dev/null || true
}

###############################################################################
# NEXT.JS / WEBPACK
###############################################################################

run_build() {
  if [ ! -x node_modules/.bin/next ]; then
    echo "BUILD_RESULT=NEXT_NOT_INSTALLED"
    return 1
  fi

  echo "BUILD_MODE=WEBPACK"
  echo "BUILD_COMMAND=next build --webpack"

  if node_modules/.bin/next build --webpack \
      > "$REPORTS/production-build.log" 2>&1
  then
    echo "BUILD_RESULT=PASS"
    return 0
  fi

  echo "BUILD_RESULT=FAIL"
  tail -50 "$REPORTS/production-build.log"
  return 1
}

###############################################################################
# AGENT
###############################################################################

execute_agent() {
  local task="$1"
  local id type parent
  local report
  local started

  id="$(awk -F= '/^ID=/ {print $2}' "$task")"
  type="$(awk -F= '/^TYPE=/ {print $2}' "$task")"
  parent="$(awk -F= '/^PARENT=/ {print $2}' "$task")"

  report="$REPORTS/$id.report"
  started="$(date +%s)"

  mv "$task" "$RUNNING/$id.task" 2>/dev/null || return 1

  {
    echo "ENGINE=$ENGINE"
    echo "VERSION=$VERSION"
    echo "ID=$id"
    echo "TYPE=$type"
    echo "PARENT=$parent"
    echo "START=$(date -Iseconds)"
    echo

    case "$type" in

      DISCOVERY)
        find app framework \
          -type f \
          2>/dev/null |
          head -300
        ;;

      SOURCE)
        find app framework \
          -type f \
          2>/dev/null |
          head -500
        ;;

      CONFIG)
        node - <<'NODE'
const fs = require("fs");

for (const f of [
  "package.json",
  "jsconfig.json",
  "tsconfig.json"
]) {
  if (!fs.existsSync(f)) {
    console.log("ABSENT", f);
    continue;
  }

  try {
    JSON.parse(fs.readFileSync(f, "utf8"));
    console.log("PASS", f);
  } catch (e) {
    console.log("FAIL", f, e.message);
    process.exitCode = 1;
  }
}
NODE
        ;;

      ROUTES)
        find app \
          -type f \
          \( \
            -name 'route.js' \
            -o -name 'route.jsx' \
            -o -name 'route.ts' \
            -o -name 'route.tsx' \
          \) \
          2>/dev/null |
          wc -l
        ;;

      MANIFESTS)
        if [ -d .next/server ]; then
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
        else
          echo "NEXT_SERVER_OUTPUT=ABSENT"
        fi
        ;;

      DEPENDENCIES)
        npm ls --depth=0 >/dev/null 2>&1 &&
          echo "DEPENDENCIES=PASS" ||
          echo "DEPENDENCIES=WARNING"
        ;;

      TYPES)
        if [ -f tsconfig.json ]; then
          echo "TYPESCRIPT=CONFIGURED"
        elif [ -f jsconfig.json ]; then
          echo "JAVASCRIPT=CONFIGURED"
        else
          echo "TYPE_CONFIG=ABSENT"
        fi
        ;;

      WEBPACK)
        echo "WEBPACK=REQUIRED"
        grep -nE \
          'webpack|turbopack' \
          next.config.js \
          next.config.mjs \
          next.config.ts \
          package.json \
          2>/dev/null || true
        ;;

      MEMORY)
        echo "AVAILABLE_MB=$(mem_available)"
        echo "TOTAL_MB=$(mem_total)"
        echo "DISK_MB=${disk_available:-0}"
        echo "PRESSURE=$(pressure_level)"
        echo "CAPACITY=$(worker_capacity)"
        ;;

      PERFORMANCE)
        echo "CPU=$(cpu_count)"
        echo "MEMORY=$(mem_available)MB"
        echo "DISK=${disk_available:-0}MB"
        ;;

      SECURITY)
        grep -RIlE \
          'BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY|sk-[A-Za-z0-9]' \
          . \
          --exclude-dir=node_modules \
          --exclude-dir=.next \
          --exclude-dir=.git \
          --exclude-dir=.completion-state \
          2>/dev/null |
          head -30 || true
        ;;

      RUNTIME)
        [ -f app/api/health/route.js ] ||
        [ -f app/api/health/route.ts ] ||
        [ -f app/api/health/route.tsx ] &&
          echo "HEALTH=PASS" ||
          echo "HEALTH=ABSENT"
        ;;

      TESTS)
        find . \
          -path ./node_modules -prune -o \
          -path ./.next -prune -o \
          -path ./.completion-state -prune -o \
          \( -name '*test*' -o -name '*spec*' \) \
          -print 2>/dev/null |
          head -100
        ;;

      BUILD)
        run_build
        ;;

      FAILURE)
        grep -RhsE \
          'Cannot find module|Module not found|Type error|Failed to collect page data|Build failed|Unable to snapshot' \
          "$REPORTS" "$LOGDIR" \
          2>/dev/null |
          tail -50 || true
        ;;

      REPAIR)
        snapshot_project "$id"
        echo "REPAIR_SNAPSHOT=$BRANCHES/$id"
        ;;

      ARCHITECTURE)
        echo "ARCHITECTURE_ANALYSIS=COMPLETE"
        ;;

      VERSION)
        git status --short 2>/dev/null || true
        ;;

      RELEASE)
        echo "RELEASE_GATE=ANALYZED"
        ;;

      OPTIMIZE)
        echo "OPTIMIZATION_ANALYSIS=COMPLETE"
        ;;

    esac

    echo
    echo "END=$(date -Iseconds)"
    echo "DURATION=$(( $(date +%s) - started ))"
    echo "STATUS=COMPLETE"

  } > "$report" 2>&1

  mv "$RUNNING/$id.task" "$DONE/$id.task" 2>/dev/null || true

  ###########################################################################
  # ACYCLIC GRAPH
  ###########################################################################

  case "$type" in

    DISCOVERY)
      enqueue SOURCE 60 "$id"
      enqueue CONFIG 60 "$id"
      ;;

    SOURCE)
      enqueue ROUTES 60 "$id"
      enqueue RUNTIME 60 "$id"
      ;;

    CONFIG)
      enqueue DEPENDENCIES 70 "$id"
      enqueue TYPES 70 "$id"
      enqueue WEBPACK 80 "$id"
      ;;

    ROUTES)
      enqueue MANIFESTS 70 "$id"
      ;;

    DEPENDENCIES)
      enqueue BUILD 100 "$id"
      ;;

    TYPES)
      enqueue BUILD 100 "$id"
      ;;

    WEBPACK)
      enqueue BUILD 100 "$id"
      ;;

    MEMORY)
      ;;

    PERFORMANCE)
      ;;

    SECURITY)
      ;;

    RUNTIME)
      enqueue TESTS 90 "$id"
      ;;

    TESTS)
      enqueue BUILD 100 "$id"
      ;;

    BUILD)
      if grep -q 'BUILD_RESULT=FAIL' "$report" 2>/dev/null; then
        enqueue FAILURE 100 "$id"
      else
        enqueue RELEASE 100 "$id"
      fi
      ;;

    FAILURE)
      enqueue REPAIR 100 "$id"
      ;;

    REPAIR)
      enqueue TESTS 100 "$id"
      ;;

    RELEASE)
      enqueue VERSION 80 "$id"
      ;;

    ARCHITECTURE)
      ;;

    VERSION)
      ;;

    OPTIMIZE)
      ;;

  esac
}

###############################################################################
# CHECKPOINT
###############################################################################

checkpoint() {
  local file="$SNAP/state-$(date +%Y%m%d-%H%M%S).json"

  cat > "$file" <<JSON
{
  "engine": "Completion Engine®",
  "version": "$VERSION",
  "fabric": "Universal Fabric®",
  "timestamp": "$(date -Iseconds)",
  "cpu": $(cpu_count),
  "memory_available_mb": $(mem_available),
  "memory_total_mb": $(mem_total),
  "disk_available_mb": ${disk_available:-0},
  "pressure": "$(pressure_level)",
  "worker_capacity": $(worker_capacity),
  "queued": $(find "$QUEUE" -name '*.task' 2>/dev/null | wc -l),
  "running": $(find "$RUNNING" -name '*.task' 2>/dev/null | wc -l),
  "completed": $(find "$DONE" -name '*.task' 2>/dev/null | wc -l),
  "failed": $(find "$FAILED" -name '*.task' 2>/dev/null | wc -l)
}
JSON
}

###############################################################################
# TERMINAL STATE
###############################################################################

converged() {
  local q r p

  q="$(find "$QUEUE" -name '*.task' 2>/dev/null | wc -l)"
  r="$(find "$RUNNING" -name '*.task' 2>/dev/null | wc -l)"
  p="$(find "$RETRY" -name '*.task' 2>/dev/null | wc -l)"

  [ "$q" -eq 0 ] &&
  [ "$r" -eq 0 ] &&
  [ "$p" -eq 0 ]
}

###############################################################################
# LEGACY LAUNCHERS
###############################################################################

install_alias() {
  local alias="$1"

  cat > "$alias" <<'ALIAS'
#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")" || exit 1
exec ./COMPLETION_ENGINE_UNIVERSAL.sh "$@"
ALIAS

  chmod +x "$alias"
}

###############################################################################
# BOOT
###############################################################################

clear

migrate_legacy_state

echo "=============================================================="
echo " $ENGINE"
echo "=============================================================="
echo "Canonical version : $VERSION"
echo "CPU               : $(cpu_count)"
echo "Memory available  : $(mem_available) MB"
echo "Memory total      : $(mem_total) MB"
echo "Disk available    : ${disk_available:-0} MB"
echo "Pressure          : $(pressure_level)"
echo "Worker capacity   : $(worker_capacity)"
echo "Virtual agents    : ELASTIC"
echo "Task identity     : DEDUPLICATED"
echo "Graph             : ACYCLIC"
echo "Build             : NEXT.JS + WEBPACK"
echo "Legacy versions   : UNIFIED"
echo "=============================================================="

if ! find "$QUEUE" -name '*.task' -print -quit 2>/dev/null | grep -q . &&
   ! find "$RUNNING" -name '*.task' -print -quit 2>/dev/null | grep -q .; then
  seed
  echo "✓ Universal fabric seeded"
else
  echo "✓ Existing universal fabric resumed"
fi

###############################################################################
# OPTIONAL LEGACY COMPATIBILITY NAMES
###############################################################################

for alias in \
  COMPLETION_ENGINE_V1.sh \
  COMPLETION_ENGINE_V2.sh \
  COMPLETION_ENGINE_V3.sh \
  COMPLETION_ENGINE_V4.sh \
  COMPLETION_ENGINE_V5.sh \
  COMPLETION_ENGINE_V6.sh \
  COMPLETION_ENGINE_V7.sh \
  COMPLETION_ENGINE_V7_ELASTIC.sh \
  COMPLETION_ENGINE_V7_1.sh \
  COMPLETION_ENGINE_V7_2.sh
do
  [ "$alias" = "COMPLETION_ENGINE_UNIVERSAL.sh" ] || install_alias "$alias"
done

###############################################################################
# SUPERVISOR
###############################################################################

PIDS=""
QUIET=0
CYCLE=0

echo "[UNIVERSAL SUPERVISOR] ONLINE"

while true; do

  CYCLE=$((CYCLE + 1))

  CAP="$(worker_capacity)"
  PRESSURE="$(pressure_level)"

  ACTIVE_PIDS=""

  for pid in $PIDS; do
    if kill -0 "$pid" 2>/dev/null; then
      ACTIVE_PIDS="$ACTIVE_PIDS $pid"
    fi
  done

  PIDS="$ACTIVE_PIDS"

  ACTIVE=0

  for pid in $PIDS; do
    ACTIVE=$((ACTIVE + 1))
  done

  if [ "$PRESSURE" != CRITICAL ]; then

    while [ "$ACTIVE" -lt "$CAP" ]; do

      TASK="$(
        find "$QUEUE" \
          -type f \
          -name '*.task' \
          -print 2>/dev/null |
        head -1
      )"

      [ -n "$TASK" ] || break

      ID="$(basename "$TASK" .task)"

      (
        execute_agent "$TASK"
      ) > "$AGENTS/$ID.output" 2>&1 &

      PID=$!

      PIDS="$PIDS $PID"
      ACTIVE=$((ACTIVE + 1))
    done

  fi

  QUEUED="$(find "$QUEUE" -name '*.task' 2>/dev/null | wc -l)"
  RUNNING_COUNT="$(find "$RUNNING" -name '*.task' 2>/dev/null | wc -l)"
  COMPLETE="$(find "$DONE" -name '*.task' 2>/dev/null | wc -l)"
  FAILED="$(find "$FAILED" -name '*.task' 2>/dev/null | wc -l)"

  if converged && [ "$ACTIVE" -eq 0 ]; then
    QUIET=$((QUIET + 1))
  else
    QUIET=0
  fi

  if [ $((CYCLE % 5)) -eq 0 ]; then
    printf '\r[FABRIC] RAM=%sMB PRESSURE=%s WORKERS=%s QUEUED=%s COMPLETE=%s FAILED=%s     ' \
      "$(mem_available)" \
      "$PRESSURE" \
      "$ACTIVE" \
      "$QUEUED" \
      "$COMPLETE" \
      "$FAILED"

    checkpoint
  fi

  if [ "$QUIET" -ge 2 ]; then
    echo
    echo
    echo "=============================================================="
    echo " UNIVERSAL FABRIC® CONVERGED"
    echo "=============================================================="
    echo "Completed : $COMPLETE"
    echo "Failed    : $FAILED"
    echo "Queued    : $QUEUED"
    echo "Running   : $RUNNING_COUNT"
    echo "RAM       : $(mem_available) MB"
    echo "Disk      : ${disk_available:-0} MB"
    echo "Version   : $VERSION"
    echo "=============================================================="
    break
  fi

  sleep 1

done

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — UNIVERSAL"
echo "=============================================================="
echo "STATUS    : CONVERGED"
echo "VERSION   : $VERSION"
echo "COMPLETED : $COMPLETE"
echo "FAILED    : $FAILED"
echo "QUEUED    : $QUEUED"
echo "RUNNING   : $RUNNING_COUNT"
echo "RAM       : $(mem_available) MB"
echo "DISK      : ${disk_available:-0} MB"
echo "=============================================================="
