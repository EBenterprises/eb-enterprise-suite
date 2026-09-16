#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG=".completion-logs/canonical-gate-$STAMP.log"
RESULT=".completion-checkpoints/canonical-gate-$STAMP"

mkdir -p .completion-logs "$RESULT"

echo "=============================================================="
echo " COMPLETION ENGINE® — CANONICAL BUILD GATE"
echo "=============================================================="

echo
echo "[1/6] Policy"

BUILD_SCRIPT="$(node -e '
const p=require("./package.json");
process.stdout.write(p.scripts?.build || "");
')"

if [ "$BUILD_SCRIPT" != "next build --webpack" ]; then
    echo "✗ Invalid build script:"
    echo "$BUILD_SCRIPT"
    exit 1
fi

echo "✓ Build script: $BUILD_SCRIPT"

echo
echo "[2/6] Runtime"

if ! command -v npm >/dev/null 2>&1; then
    echo "✗ npm unavailable"
    exit 1
fi

if [ ! -x node_modules/.bin/next ]; then
    echo "✗ local Next executable missing"
    exit 1
fi

echo "✓ npm available"
echo "✓ local Next available"

echo
echo "[3/6] Environment"

unset TURBOPACK
unset NEXT_TURBOPACK
unset NEXT_PRIVATE_TURBOPACK

echo "✓ Turbopack environment variables cleared"

echo
echo "[4/6] Controlled build"

rm -rf .next

set +e
npm run build >"$LOG" 2>&1
STATUS=$?
set -e

echo "Build exit: $STATUS"

echo
echo "[5/6] Artifact gate"

NEXT_PASS=0
SERVER_PASS=0
MANIFEST_PASS=0

[ -d ".next" ] && NEXT_PASS=1
[ -d ".next/server" ] && SERVER_PASS=1
[ -f ".next/server/pages-manifest.json" ] && MANIFEST_PASS=1

echo "NEXT_DIRECTORY=$([ "$NEXT_PASS" -eq 1 ] && echo PASS || echo FAIL)"
echo "NEXT_SERVER=$([ "$SERVER_PASS" -eq 1 ] && echo PASS || echo FAIL)"
echo "PAGES_MANIFEST=$([ "$MANIFEST_PASS" -eq 1 ] && echo PASS || echo FAIL)"

echo
echo "[6/6] Gate"

GATE=FAIL

if [ "$STATUS" -eq 0 ] &&
   [ "$NEXT_PASS" -eq 1 ] &&
   [ "$SERVER_PASS" -eq 1 ] &&
   [ "$MANIFEST_PASS" -eq 1 ]; then
    GATE=PASS
fi

{
    echo "TIMESTAMP=$STAMP"
    echo "BUILD_STATUS=$STATUS"
    echo "BUILD_SCRIPT=$BUILD_SCRIPT"
    echo "BUILD_ENGINE=webpack"
    echo "TURBOPACK=disabled"
    echo "NEXT_DIRECTORY=$([ "$NEXT_PASS" -eq 1 ] && echo PASS || echo FAIL)"
    echo "NEXT_SERVER=$([ "$SERVER_PASS" -eq 1 ] && echo PASS || echo FAIL)"
    echo "PAGES_MANIFEST=$([ "$MANIFEST_PASS" -eq 1 ] && echo PASS || echo FAIL)"
    echo "GATE=$GATE"
    echo "LOG=$LOG"
} > "$RESULT/RESULT"

if [ "$GATE" = "PASS" ]; then
    echo "=============================================================="
    echo " COMPLETION ENGINE® — CANONICAL GATE PASS"
    echo "=============================================================="
    echo "Production build verified."
    echo "Webpack verified."
    echo "Server output verified."
    echo "Pages manifest verified."
    echo "=============================================================="
    exit 0
fi

echo "=============================================================="
echo " COMPLETION ENGINE® — CANONICAL GATE FAILED"
echo "=============================================================="

echo
echo "Failure signals:"
grep -nEi \
'error|failed|failure|exception|fatal|ENOENT|pages-manifest|bundler|webpack|turbopack|worker|npm ERR|ELIFECYCLE' \
"$LOG" | tail -100 || true

echo
echo "Last 60 lines:"
tail -60 "$LOG"

exit 1
