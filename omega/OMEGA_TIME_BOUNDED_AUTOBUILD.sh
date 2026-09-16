#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$HOME/omega"
cd "$ROOT" || exit 1

STATE="$ROOT/.omega"
LOG="$STATE/autobuild.log"
CHECKPOINT="$STATE/autobuild.checkpoint"
LOCK="$STATE/autobuild.lock"

mkdir -p "$STATE"

exec 9>"$LOCK"
flock -n 9 || {
  echo "OMEGA® autobuild already running."
  exit 1
}

TIME_LIMIT=0
MODE="continuous"

usage() {
  cat <<USAGE
OMEGA® TIME-BOUNDED AUTOBUILD

Usage:
  ./OMEGA_TIME_BOUNDED_AUTOBUILD.sh --time 30s
  ./OMEGA_TIME_BOUNDED_AUTOBUILD.sh --time 30m
  ./OMEGA_TIME_BOUNDED_AUTOBUILD.sh --time 4h
  ./OMEGA_TIME_BOUNDED_AUTOBUILD.sh --time 24h
  ./OMEGA_TIME_BOUNDED_AUTOBUILD.sh --time 7d
  ./OMEGA_TIME_BOUNDED_AUTOBUILD.sh --verify
USAGE
}

duration() {
  case "$1" in
    *s) echo "${1%s}" ;;
    *m) echo $(( ${1%m} * 60 )) ;;
    *h) echo $(( ${1%h} * 3600 )) ;;
    *d) echo $(( ${1%d} * 86400 )) ;;
    *) return 1 ;;
  esac
}

while (($#)); do
  case "$1" in
    --time)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      TIME_LIMIT="$(duration "$2")" || {
        echo "Invalid duration: $2"
        exit 2
      }
      shift 2
      ;;
    --verify)
      MODE="verify"
      shift
      ;;
    --resume)
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ "$MODE" != "verify" && "$TIME_LIMIT" -le 0 ]]; then
  echo "ERROR: time allocation required."
  usage
  exit 2
fi

NOW="$(date +%s)"
END=$((NOW + TIME_LIMIT))
CYCLE=0
PASS=0
FAIL=0

log() {
  printf '[%s] %s\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    "$*" | tee -a "$LOG"
}

checkpoint() {
  cat > "$CHECKPOINT" <<JSON
{
  "system": "OMEGA®",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "cycle": $CYCLE,
  "passes": $PASS,
  "failures": $FAIL,
  "remaining_seconds": $(( END > $(date +%s) ? END - $(date +%s) : 0 ))
}
JSON
}

run_sweep() {
  if [[ -x "$ROOT/OMEGA_FINAL_SWEEP.sh" ]]; then
    "$ROOT/OMEGA_FINAL_SWEEP.sh"
  else
    bash "$ROOT/OMEGA_FINAL_SWEEP.sh"
  fi
}

run_existing_builders() {
  local script
  for script in \
    OMEGA_BUILD.sh \
    OMEGA_CONTINUE.sh \
    OMEGA_COMPLETE.sh \
    OMEGA_ENGINE.sh \
    OMEGA_REPAIR.sh \
    OMEGA_AUTO_REPAIR.sh \
    OMEGA_OPTIMIZE.sh \
    OMEGA_DISCOVER.sh \
    OMEGA_EXPLORE.sh \
    OMEGA_SYNTHESIS.sh
  do
    [[ -f "$ROOT/$script" ]] || continue

    log "RUN: $script"

    if [[ -x "$ROOT/$script" ]]; then
      "$ROOT/$script" || return 1
    else
      bash "$ROOT/$script" || return 1
    fi

    [[ "$(date +%s)" -lt "$END" ]] || return 0
  done

  return 0
}

verify() {
  log "FULL VERIFICATION PASS"

  if [[ -x "$ROOT/OMEGA_FINAL_SWEEP.sh" ]]; then
    "$ROOT/OMEGA_FINAL_SWEEP.sh"
  else
    bash "$ROOT/OMEGA_FINAL_SWEEP.sh"
  fi
}

if [[ "$MODE" == "verify" ]]; then
  verify
  exit $?
fi

log "=========================================="
log "OMEGA® AUTONOMOUS BUILD WINDOW STARTED"
log "ALLOCATED: ${TIME_LIMIT}s"
log "END: $(date -u -d "@$END" '+%Y-%m-%dT%H:%M:%SZ')"
log "=========================================="

while [[ "$(date +%s)" -lt "$END" ]]; do
  CYCLE=$((CYCLE + 1))

  log "CYCLE $CYCLE"

  if run_existing_builders; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    log "Builder failure detected; entering verification/repair sweep."
  fi

  [[ "$(date +%s)" -lt "$END" ]] || break

  if run_sweep; then
    PASS=$((PASS + 1))
    log "VERIFICATION: PASS"
  else
    FAIL=$((FAIL + 1))
    log "VERIFICATION: FAIL"
  fi

  checkpoint

  [[ "$(date +%s)" -lt "$END" ]] || break

  sleep 1
done

log "ALLOCATED BUILD WINDOW COMPLETE"
checkpoint

log "FINAL VERIFICATION"

if verify; then
  STATUS="VERIFIED"
else
  STATUS="CHECKPOINTED"
fi

cat > "$STATE/final-state.json" <<JSON
{
  "system": "OMEGA®",
  "status": "$STATUS",
  "completed_at": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "allocated_seconds": $TIME_LIMIT,
  "cycles": $CYCLE,
  "passes": $PASS,
  "failures": $FAIL
}
JSON

echo
echo "=========================================="
echo "OMEGA® AUTOBUILD COMPLETE"
echo "STATUS: $STATUS"
echo "CYCLES: $CYCLE"
echo "PASSES: $PASS"
echo "FAILURES: $FAIL"
echo "CHECKPOINT: $CHECKPOINT"
echo "=========================================="
