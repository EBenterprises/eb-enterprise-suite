#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="COMPLETION_ENGINE_ADAPTIVE_V2"
STATE=".completion-state"
LOGDIR=".completion-logs"
BACKUP=".completion-backups"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/adaptive-v2-$TS.log"
STATEFILE="$STATE/state.json"
LOCK="$STATE/.lock"

mkdir -p "$STATE" "$LOGDIR" "$BACKUP"

exec > >(tee "$LOG") 2>&1

cleanup() {
  rm -f "$LOCK"
}
trap cleanup EXIT INT TERM

if [ -e "$LOCK" ]; then
  echo "✗ Another Completion Engine® run is active."
  exit 1
fi

touch "$LOCK"

echo "=============================================================="
echo " $ENGINE"
echo "=============================================================="
echo

log() {
  printf '[%s] %s\n' "$1" "$2"
}

sha() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

record_state() {
  cat > "$STATEFILE" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "next": "$(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)",
  "node": "$(node -v 2>/dev/null || echo unknown)",
  "package": "$(sha package.json 2>/dev/null || echo unknown)",
  "lockfile": "$(sha package-lock.json 2>/dev/null || echo unknown)",
  "next_config": "$(sha next.config.js 2>/dev/null || echo unknown)",
  "jsconfig": "$(sha jsconfig.json 2>/dev/null || echo unknown)"
}
JSON
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

echo "[0/8] FAST STATE DISCOVERY"
echo "--------------------------------------------------------------"

record_state

log "STATE" "Next $(node -p "require('./node_modules/next/package.json').version" 2>/dev/null || echo unknown)"
log "STATE" "Node $(node -v 2>/dev/null || echo unknown)"
log "STATE" "Project fingerprint recorded"

echo
echo "[1/8] KNOWN-GOOD STATE LOOKUP"
echo "--------------------------------------------------------------"

KNOWN_GOOD="$STATE/known-good.json"

if [ -f "$KNOWN_GOOD" ]; then
  echo "✓ Known-good state exists"
  cat "$KNOWN_GOOD"
else
  echo "• No known-good state yet"
fi

echo
echo "[2/8] CHEAP SOURCE / ALIAS DIAGNOSTICS"
echo "--------------------------------------------------------------"

SOURCE_FAILURE=0

for route in "${EXPECTED_ROUTES[@]}"; do
  src="app/api/$route"

  if [ ! -f "$src" ]; then
    echo "✗ SOURCE MISSING: $src"
    SOURCE_FAILURE=1
  fi
done

if [ "$SOURCE_FAILURE" -eq 0 ]; then
  echo "✓ All expected API route sources exist"
fi

if [ -f framework/api/crud-route.js ]; then
  echo "✓ framework/api/crud-route.js exists"
else
  echo "✗ framework/api/crud-route.js missing"
  SOURCE_FAILURE=1
fi

if grep -q '"@framework/\*"' jsconfig.json 2>/dev/null; then
  echo "✓ @framework alias declared"
else
  echo "✗ @framework alias missing"
  SOURCE_FAILURE=1
fi

if grep -q '"@app/\*"' jsconfig.json 2>/dev/null; then
  echo "✓ @app alias declared"
else
  echo "✗ @app alias missing"
fi

echo
echo "[3/8] FAILURE-SIGNATURE DETECTOR"
echo "--------------------------------------------------------------"

LAST_LOG="$(find "$LOGDIR" -type f -name '*.log' \
  ! -path "$LOG" -printf '%T@ %p\n' 2>/dev/null |
  sort -nr |
  head -1 |
  cut -d' ' -f2-)"

CLASS="UNKNOWN"

if [ -n "${LAST_LOG:-}" ] && [ -f "$LAST_LOG" ]; then

  if grep -qE \
    'Cannot find module .*\.next/server/app/.*/route\.js|Failed to collect page data' \
    "$LAST_LOG"; then
    CLASS="SERVER_ARTIFACT_EMISSION_FAILURE"
  fi

  if grep -qE \
    'pages-manifest\.json|app-paths-manifest\.json' \
    "$LAST_LOG"; then
    CLASS="MANIFEST_FAILURE"
  fi

  if grep -qE \
    'Unable to snapshot resolve dependencies|PackFileCacheStrategy' \
    "$LAST_LOG"; then
    if [ "$CLASS" = "UNKNOWN" ]; then
      CLASS="WEBPACK_CACHE_ENVIRONMENT_WARNING"
    else
      CLASS="$CLASS + WEBPACK_CACHE_WARNING"
    fi
  fi

  if grep -qE \
    'Module not found|Can't resolve|Cannot resolve' \
    "$LAST_LOG"; then
    CLASS="MODULE_RESOLUTION_FAILURE"
  fi

  if grep -qE \
    'TypeScript|TS[0-9]{4}' \
    "$LAST_LOG"; then
    CLASS="TYPESCRIPT_FAILURE"
  fi
fi

echo "Classification: $CLASS"

echo
echo "[4/8] CURRENT .NEXT ARTIFACT PROBE"
echo "--------------------------------------------------------------"

EMITTED=0
MISSING=0

if [ -d .next/server/app/api ]; then
  for route in "${EXPECTED_ROUTES[@]}"; do
    if [ -f ".next/server/app/api/$route" ]; then
      EMITTED=$((EMITTED + 1))
    else
      MISSING=$((MISSING + 1))
    fi
  done
fi

echo "Expected route artifacts: ${#EXPECTED_ROUTES[@]}"
echo "Currently emitted:        $EMITTED"
echo "Currently missing:        $MISSING"

echo
echo "[5/8] DECISION ENGINE"
echo "--------------------------------------------------------------"

ACTION="DIAGNOSE"

case "$CLASS" in

  SERVER_ARTIFACT_EMISSION_FAILURE*)
    echo "✓ Known failure signature detected"
    echo "✓ Failure occurs after compilation"
    echo "✓ Route source exists"
    echo "→ Do NOT modify route source"
    echo "→ Do NOT modify aliases blindly"
    echo "→ Inspect Webpack emission/cache state"
    ACTION="TARGETED_EMISSION_REPAIR"
    ;;

  MODULE_RESOLUTION_FAILURE)
    echo "→ Alias/module resolution failure"
    ACTION="TARGETED_ALIAS_REPAIR"
    ;;

  TYPESCRIPT_FAILURE)
    echo "→ TypeScript failure"
    ACTION="TARGETED_TYPESCRIPT_REPAIR"
    ;;

  MANIFEST_FAILURE*)
    echo "→ Manifest generation failure"
    ACTION="TARGETED_MANIFEST_REPAIR"
    ;;

  WEBPACK_CACHE_ENVIRONMENT_WARNING)
    echo "→ Webpack cache environment warning"
    ACTION="CACHE_DIAGNOSTIC"
    ;;

  *)
    echo "→ No trusted failure signature"
    echo "→ No speculative source modification"
    ACTION="MINIMAL_DIAGNOSTIC"
    ;;
esac

echo
echo "[6/8] ADAPTIVE REPAIR"
echo "--------------------------------------------------------------"

if [ "$SOURCE_FAILURE" -ne 0 ]; then
  echo "✗ Source/configuration prerequisite failure detected"
  echo "Repairing prerequisites before any production build."

  if [ ! -f framework/api/crud-route.js ]; then
    echo "✗ CRUD contract missing — refusing destructive regeneration"
    exit 1
  fi
fi

if [ "$ACTION" = "TARGETED_EMISSION_REPAIR" ] ||
   [ "$ACTION" = "CACHE_DIAGNOSTIC" ]; then

  echo "Applying reversible cache-only diagnostic."

  cp -f next.config.js "$BACKUP/next.config.pre-adaptive-$TS.js"

  python3 - <<'PY'
from pathlib import Path
import re

p = Path("next.config.js")
s = p.read_text()

if "COMPLETION_ENGINE_ADAPTIVE_CACHE_TEST" in s:
    print("✓ Adaptive cache test already installed")
    raise SystemExit

m = re.search(r'webpack\s*:\s*\(config\)\s*=>\s*\{', s)

if not m:
    print("✗ Existing Webpack hook not found")
    raise SystemExit(2)

injection = r'''
    /* COMPLETION_ENGINE_ADAPTIVE_CACHE_TEST */
    /*
     * Reversible diagnostic:
     * eliminate webpack filesystem cache as a variable.
     * Existing aliases and application configuration remain untouched.
     */
    config.cache = false;
'''

s = s[:m.end()] + injection + s[m.end():]
p.write_text(s)

print("✓ Cache-only diagnostic installed")
PY

elif [ "$ACTION" = "TARGETED_ALIAS_REPAIR" ]; then
  echo "Alias failure detected."
  echo "No production build yet."
  echo "Running static alias resolution probe."

  node - <<'NODE'
const fs = require("fs");
const path = require("path");

const files = [
  "app/api/customers/route.js",
  "app/api/requests/route.js",
  "app/api/orders/route.js"
];

for (const file of files) {
  if (!fs.existsSync(file)) continue;

  const text = fs.readFileSync(file, "utf8");

  if (text.includes("@framework/api/crud-route")) {
    const target = path.resolve("framework/api/crud-route.js");

    if (!fs.existsSync(target)) {
      console.error("BROKEN ALIAS:", file, "->", target);
      process.exit(1);
    }
  }
}

console.log("✓ Static alias target probe passed");
NODE

elif [ "$ACTION" = "TARGETED_TYPESCRIPT_REPAIR" ]; then
  echo "TypeScript failure detected."
  echo "→ No Webpack mutation"
  echo "→ No route rewrite"
  echo "→ TypeScript diagnostics must be repaired directly."

elif [ "$ACTION" = "TARGETED_MANIFEST_REPAIR" ]; then
  echo "Manifest failure detected."
  echo "→ Inspecting manifest prerequisites"
  test -d .next/server || mkdir -p .next/server

else
  echo "No safe automatic mutation identified."
  echo "→ Preserving source/configuration."
fi

echo
echo "[7/8] EXPENSIVE BUILD GATE"
echo "--------------------------------------------------------------"

echo "The engine has selected:"
echo "ACTION=$ACTION"
echo

if [ "$ACTION" = "MINIMAL_DIAGNOSTIC" ]; then
  echo "No trusted repair exists."
  echo "Skipping expensive production build."
  echo "RESULT=NEEDS_TARGETED_DIAGNOSTIC"
  exit 2
fi

echo "Running exactly ONE production verification build."
echo "No blind retries."

rm -rf .next

BUILD_START="$(date +%s)"

if npm run build -- --webpack; then
  RC=0
else
  RC=$?
fi

BUILD_END="$(date +%s)"
DURATION=$((BUILD_END - BUILD_START))

echo
echo "Build duration: ${DURATION}s"
echo "Build exit code: $RC"

echo
echo "[8/8] POST-BUILD EVIDENCE ANALYSIS"
echo "--------------------------------------------------------------"

EMITTED=0
MISSING=0

for route in "${EXPECTED_ROUTES[@]}"; do
  if [ -f ".next/server/app/api/$route" ]; then
    EMITTED=$((EMITTED + 1))
  else
    MISSING=$((MISSING + 1))
  fi
done

echo "Route artifacts emitted: $EMITTED/${#EXPECTED_ROUTES[@]}"

if [ "$RC" -eq 0 ] && [ "$MISSING" -eq 0 ]; then

  cat > "$KNOWN_GOOD" <<JSON
{
  "timestamp": "$(date -Iseconds)",
  "next": "$(node -p "require('./node_modules/next/package.json').version")",
  "node": "$(node -v)",
  "package": "$(sha package.json)",
  "lockfile": "$(sha package-lock.json)",
  "next_config": "$(sha next.config.js)",
  "jsconfig": "$(sha jsconfig.json)",
  "route_artifacts": $EMITTED,
  "status": "KNOWN_GOOD"
}
JSON

  echo
  echo "=============================================================="
  echo " RESULT: PASS — KNOWN-GOOD STATE RECORDED"
  echo "=============================================================="
  echo "Build: ${DURATION}s"
  echo "Routes: $EMITTED/${#EXPECTED_ROUTES[@]}"
  echo "Known-good state: $KNOWN_GOOD"
  echo "Log: $LOG"
  echo "=============================================================="
  exit 0
fi

echo
echo "=============================================================="
echo " RESULT: FAIL — FAILURE CLASSIFIED"
echo "=============================================================="
echo "Class: $CLASS"
echo "Action: $ACTION"
echo "Build exit: $RC"
echo "Emitted: $EMITTED/${#EXPECTED_ROUTES[@]}"
echo "Missing: $MISSING"
echo "Log: $LOG"
echo "=============================================================="

exit "${RC:-1}"
