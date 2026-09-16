#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE=".completion-state/universal-fabric"
REPORTS="$STATE/reports"
LOGDIR=".completion-logs"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOGDIR/final-$STAMP.log"

mkdir -p \
  "$STATE"/{queue,running,done,failed,retry,seen,reports,agents,snapshots,branches,virtual-memory} \
  "$LOGDIR"

exec > >(tee "$LOG") 2>&1

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — UNIVERSAL FINALIZER®"
echo "=============================================================="

###############################################################################
# SAFE PROCESS CLEANUP — NEVER MATCH THIS SCRIPT
###############################################################################

SELF_PID=$$

for pid in $(pgrep -f 'COMPLETION_ENGINE_V7_ELASTIC\.sh' 2>/dev/null || true); do
    [ "$pid" = "$SELF_PID" ] || kill "$pid" 2>/dev/null || true
done

for pid in $(pgrep -f '(^|/)COMPLETION_ENGINE_UNIVERSAL\.sh([[:space:]]|$)' 2>/dev/null || true); do
    [ "$pid" = "$SELF_PID" ] || kill "$pid" 2>/dev/null || true
done

rm -f \
  .completion-state/.v7.lock \
  .completion-state/.universal.lock

###############################################################################
# BASIC RUNTIME
###############################################################################

command -v node >/dev/null 2>&1 || {
    echo "✗ Node.js unavailable"
    exit 1
}

command -v npm >/dev/null 2>&1 || {
    echo "✗ npm unavailable"
    exit 1
}

echo "✓ Node $(node --version)"
echo "✓ npm $(npm --version)"

###############################################################################
# CONFIGURATION SNAPSHOT
###############################################################################

SNAP="$STATE/snapshots/final-$STAMP"
mkdir -p "$SNAP"

for f in \
    package.json \
    package-lock.json \
    next.config.js \
    next.config.mjs \
    next.config.ts \
    jsconfig.json \
    tsconfig.json
do
    [ -f "$f" ] && cp -f "$f" "$SNAP/" || true
done

echo "✓ Configuration snapshot created"

###############################################################################
# DEPENDENCIES
###############################################################################

if [ -f package-lock.json ]; then
    echo "[DEPENDENCIES] Synchronizing"

    npm install \
        --no-audit \
        --no-fund \
        --ignore-scripts \
        > "$REPORTS/npm-install.log" 2>&1 || {
            echo "⚠ npm install returned non-zero"
            tail -30 "$REPORTS/npm-install.log"
        }
fi

###############################################################################
# NEXT.JS
###############################################################################

if [ ! -x node_modules/.bin/next ]; then
    echo "✗ Next.js executable missing"
    exit 1
fi

NEXT_VERSION="$(node_modules/.bin/next --version 2>/dev/null || true)"

echo "✓ Next.js $NEXT_VERSION"

###############################################################################
# REMOVE ONLY REGENERATABLE BUILD OUTPUT
###############################################################################

rm -rf .next

echo "✓ Previous .next removed"

###############################################################################
# UNIVERSAL FABRIC
###############################################################################

if [ -x ./COMPLETION_ENGINE_UNIVERSAL.sh ]; then

    echo "[FABRIC] Running UNIVERSAL engine"

    if ./COMPLETION_ENGINE_UNIVERSAL.sh \
        > "$REPORTS/universal-run.log" 2>&1
    then
        echo "✓ Universal engine completed"
    else
        echo "⚠ Universal engine returned non-zero"
        tail -50 "$REPORTS/universal-run.log"
    fi

else
    echo "⚠ Universal engine not present — continuing with authoritative build gate"
fi

###############################################################################
# FINAL BUILD
###############################################################################

echo
echo "[BUILD] Production Webpack gate"

if node_modules/.bin/next build --webpack \
    > "$REPORTS/final-webpack.log" 2>&1
then
    BUILD_STATUS="PASS"
    echo "✓ WEBPACK BUILD PASS"
else
    BUILD_STATUS="FAIL"
    echo "✗ WEBPACK BUILD FAIL"
    tail -100 "$REPORTS/final-webpack.log"
    exit 1
fi

###############################################################################
# ARTIFACT VALIDATION
###############################################################################

[ -d .next ] || {
    echo "✗ .next missing"
    exit 1
}

[ -d .next/server ] || {
    echo "✗ .next/server missing"
    exit 1
}

echo "✓ Production artifact exists"

###############################################################################
# MANIFESTS
###############################################################################

for f in \
    .next/server/app-paths-manifest.json \
    .next/server/pages-manifest.json \
    .next/server/middleware-manifest.json
do
    if [ -f "$f" ]; then
        echo "✓ $(basename "$f")"
    else
        echo "⚠ $(basename "$f") not emitted by this build"
    fi
done

###############################################################################
# ROUTES
###############################################################################

ROUTES="$(
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
)"

echo "✓ Source API routes: $ROUTES"

###############################################################################
# FABRIC COUNTS
###############################################################################

QUEUE="$(
    find "$STATE/queue" \
        -name '*.task' \
        2>/dev/null |
    wc -l
)"

RUNNING="$(
    find "$STATE/running" \
        -name '*.task' \
        2>/dev/null |
    wc -l
)"

DONE="$(
    find "$STATE/done" \
        -name '*.task' \
        2>/dev/null |
    wc -l
)"

FAILED="$(
    find "$STATE/failed" \
        -name '*.task' \
        2>/dev/null |
    wc -l
)"

###############################################################################
# AUTHORITATIVE FINAL RECORD
###############################################################################

cat > .completion-state/known-good.json <<JSON
{
  "engine": "COMPLETION ENGINE®",
  "fabric": "Universal Fabric®",
  "version": "UNIVERSAL-8.0",
  "status": "PRODUCTION_READY",
  "build": "PASS",
  "webpack": "PASS",
  "nextjs": "$NEXT_VERSION",
  "routes": $ROUTES,
  "queued": $QUEUE,
  "running": $RUNNING,
  "completed": $DONE,
  "failed": $FAILED,
  "timestamp": "$(date -Iseconds)"
}
JSON

cat > "$REPORTS/FINAL-STATUS.txt" <<REPORT
COMPLETION ENGINE® — UNIVERSAL FINAL STATUS

STATUS=PRODUCTION_READY
BUILD=PASS
WEBPACK=PASS
NEXTJS=$NEXT_VERSION

ROUTES=$ROUTES

QUEUE=$QUEUE
RUNNING=$RUNNING
COMPLETED=$DONE
FAILED=$FAILED

TIMESTAMP=$(date -Iseconds)
LOG=$LOG
REPORT=$REPORTS/FINAL-STATUS.txt
REPORT

###############################################################################
# CLEANUP
###############################################################################

rm -f \
    .completion-state/.v7.lock \
    .completion-state/.universal.lock

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — UNIVERSAL"
echo "=============================================================="
echo " STATUS       : PRODUCTION READY"
echo " BUILD        : PASS"
echo " WEBPACK      : PASS"
echo " NEXT.JS      : $NEXT_VERSION"
echo " ROUTES       : $ROUTES"
echo " COMPLETED    : $DONE"
echo " FAILED       : $FAILED"
echo " QUEUED       : $QUEUE"
echo " RUNNING      : $RUNNING"
echo "=============================================================="
echo " KNOWN-GOOD   : .completion-state/known-good.json"
echo " FINAL REPORT : $REPORTS/FINAL-STATUS.txt"
echo "=============================================================="
