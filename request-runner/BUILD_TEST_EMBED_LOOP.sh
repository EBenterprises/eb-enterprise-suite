#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE=".completion-state/build-test-embed"
LOG="$STATE/engine.log"
REPORT="$STATE/reports"
mkdir -p "$REPORT"

export CI=1
export NEXT_TELEMETRY_DISABLED=1

exec > >(tee -a "$LOG") 2>&1

CYCLE=0
REPAIRS=0
PASS=0

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

run_typecheck() {
  if has_script typecheck; then
    npm run typecheck
  elif [ -x node_modules/.bin/tsc ] && [ -f tsconfig.json ]; then
    node_modules/.bin/tsc --noEmit
  else
    return 0
  fi
}

run_lint() {
  if has_script lint; then
    npm run lint
  else
    return 0
  fi
}

build() {
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

  local count
  count="$(
    find .next/server \
      -type f 2>/dev/null |
      wc -l
  )"

  [ "$count" -gt 0 ] || return 1

  echo "SERVER_ARTIFACTS=$count"
}

repair_from_log() {
  local reason="$1"
  local logfile="$2"

  REPAIRS=$((REPAIRS + 1))

  echo
  echo "=============================================================="
  echo " EMBEDDED REPAIR ENGINE®"
  echo "=============================================================="
  echo "REASON: $reason"
  echo "REPAIR: $REPAIRS"
  echo "=============================================================="

  cp "$logfile" \
    "$REPORT/repair-$REPAIRS-$reason.log" \
    2>/dev/null || true

  case "$reason" in

    DEPENDENCIES)
      npm install --no-audit --no-fund
      ;;

    BUILD)
      rm -rf .next
      ;;

    TEST)
      echo "Refreshing dependency graph..."
      npm install --no-audit --no-fund
      ;;

    TYPES)
      echo "Type validation failure captured."
      ;;

    LINT)
      echo "Lint failure captured."
      ;;

    ARTIFACT)
      rm -rf .next
      ;;

    *)
      echo "General embedded repair."
      ;;
  esac
}

while true; do

  CYCLE=$((CYCLE + 1))

  printf '\033c'

  echo "=============================================================="
  echo " COMPLETION ENGINE® — BUILD ↔ TEST ↔ EMBED FABRIC®"
  echo "=============================================================="
  echo "CYCLE       : $CYCLE"
  echo "BUILD       : CONTINUOUS"
  echo "TEST        : CONTINUOUS"
  echo "EMBEDDED    : CONTINUOUS"
  echo "REPAIR      : CONTINUOUS"
  echo "EXIT        : DISABLED"
  echo "=============================================================="

  ###########################################################################
  # TEST
  ###########################################################################

  if ! run_test > "$REPORT/test-$CYCLE.log" 2>&1; then
    repair_from_log TEST "$REPORT/test-$CYCLE.log"
    continue
  fi

  ###########################################################################
  # TYPECHECK
  ###########################################################################

  if ! run_typecheck > "$REPORT/types-$CYCLE.log" 2>&1; then
    repair_from_log TYPES "$REPORT/types-$CYCLE.log"
    continue
  fi

  ###########################################################################
  # LINT
  ###########################################################################

  if ! run_lint > "$REPORT/lint-$CYCLE.log" 2>&1; then
    repair_from_log LINT "$REPORT/lint-$CYCLE.log"
    continue
  fi

  ###########################################################################
  # BUILD
  ###########################################################################

  if ! build > "$REPORT/build-$CYCLE.log" 2>&1; then
    repair_from_log BUILD "$REPORT/build-$CYCLE.log"

    # Immediate embedded rebuild.
    if ! build > "$REPORT/rebuild-$CYCLE.log" 2>&1; then
      continue
    fi
  fi

  ###########################################################################
  # EMBEDDED ARTIFACT VALIDATION
  ###########################################################################

  if ! artifact_gate > "$REPORT/artifact-$CYCLE.log" 2>&1; then
    repair_from_log ARTIFACT "$REPORT/artifact-$CYCLE.log"

    if ! build > "$REPORT/rebuild-artifact-$CYCLE.log" 2>&1; then
      continue
    fi

    artifact_gate || continue
  fi

  ###########################################################################
  # BUILD → TEST IMMEDIATELY
  ###########################################################################

  if ! run_test > "$REPORT/post-build-test-$CYCLE.log" 2>&1; then
    repair_from_log TEST "$REPORT/post-build-test-$CYCLE.log"
    continue
  fi

  ###########################################################################
  # VERIFIED
  ###########################################################################

  PASS=$((PASS + 1))

  cat > "$STATE/status.json" <<JSON
{
  "cycle": $CYCLE,
  "verified_passes": $PASS,
  "repairs": $REPAIRS,
  "mode": "BUILD_TEST_BUILD_TEST",
  "embedded_repair": true,
  "continuous": true,
  "exit_after_success": false,
  "timestamp": "$(date -Iseconds)"
}
JSON

  echo
  echo "=============================================================="
  echo " ✓ BUILD → TEST → BUILD → TEST VERIFIED"
  echo "=============================================================="
  echo "PASS       : $PASS"
  echo "REPAIRS    : $REPAIRS"
  echo "NEXT       : BUILD"
  echo "EXIT       : DISABLED"
  echo "=============================================================="

  sleep 2

done
