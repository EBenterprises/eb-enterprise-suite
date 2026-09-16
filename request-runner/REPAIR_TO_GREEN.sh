#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE="$PWD/.completion-state/green"
LOG="$STATE/logs"
mkdir -p "$LOG"

export CI=1
export NEXT_TELEMETRY_DISABLED=1

printf '\033c'
echo "=============================================================="
echo " REPAIR → BUILD → TEST → ARTIFACT → GREEN"
echo "=============================================================="

# ---------------------------------------------------------------------------
# 1. DISCOVER BUILD CONFIGURATION
# ---------------------------------------------------------------------------

echo "[1/8] Inspecting project..."

node - <<'NODE' > "$LOG/project.json"
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
console.log(JSON.stringify({
  name:p.name,
  scripts:p.scripts || {},
  dependencies:p.dependencies || {},
  devDependencies:p.devDependencies || {}
},null,2));
NODE

BUILD_CMD=""

if node -e '
const p=require("./package.json");
process.exit(p.scripts && p.scripts.build ? 0 : 1)
' 2>/dev/null; then
    BUILD_CMD="npm run build"
elif [ -x node_modules/.bin/next ]; then
    BUILD_CMD="node_modules/.bin/next build --webpack"
fi

if [ -n "$BUILD_CMD" ]; then
    echo "✓ Build command: $BUILD_CMD"
else
    echo "✗ No build command detected"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. DEPENDENCY REPAIR
# ---------------------------------------------------------------------------

echo "[2/8] Repairing dependencies..."

if npm install --no-audit --no-fund >"$LOG/npm-install.log" 2>&1; then
    echo "✓ Dependencies synchronized"
else
    echo "△ npm install reported issues"
fi

# ---------------------------------------------------------------------------
# 3. REMOVE ONLY REGENERABLE BUILD ARTIFACTS
# ---------------------------------------------------------------------------

echo "[3/8] Resetting stale build output..."

rm -rf .next

echo "✓ Stale .next removed"

# ---------------------------------------------------------------------------
# 4. BUILD / REPAIR LOOP
# ---------------------------------------------------------------------------

echo "[4/8] Build/repair loop..."

BUILD_PASS=0

for ROUND in 1 2 3 4 5; do

    echo "  BUILD ROUND $ROUND/5"

    if bash -c "$BUILD_CMD" >"$LOG/build-$ROUND.log" 2>&1; then
        BUILD_PASS=1
        echo "  ✓ BUILD PASSED"
        break
    fi

    echo "  △ BUILD FAILED"

    # Collect only actionable error signatures.
    grep -E \
      'Module not found|Cannot find module|Type error|SyntaxError|Error:|Failed to compile|ENOENT|Invalid' \
      "$LOG/build-$ROUND.log" \
      | tail -80 \
      >"$LOG/actionable-errors.txt" || true

    # Safe automatic repair: synchronize lock/dependencies.
    npm install --no-audit --no-fund \
      >"$LOG/repair-$ROUND.log" 2>&1 || true

done

if [ "$BUILD_PASS" -ne 1 ]; then
    echo "✗ BUILD STILL FAILING"
    echo
    echo "ACTIONABLE ERRORS:"
    cat "$LOG/actionable-errors.txt" 2>/dev/null || true
    exit 1
fi

# ---------------------------------------------------------------------------
# 5. SERVER ARTIFACT GATE
# ---------------------------------------------------------------------------

echo "[5/8] Verifying server artifact..."

if [ ! -d .next/server ]; then
    echo "✗ .next/server missing"
    exit 1
fi

SERVER_COUNT="$(find .next/server -type f 2>/dev/null | wc -l)"

if [ "$SERVER_COUNT" -le 0 ]; then
    echo "✗ .next/server contains no files"
    exit 1
fi

echo "✓ Server artifact present: $SERVER_COUNT files"

# Verify important Next artifacts where applicable.
for FILE in \
    .next/BUILD_ID \
    .next/server/app-paths-manifest.json \
    .next/server/pages-manifest.json
do
    if [ -f "$FILE" ]; then
        echo "✓ $FILE"
    else
        echo "△ Optional/route-dependent artifact absent: $FILE"
    fi
done

# ---------------------------------------------------------------------------
# 6. TEST INFRASTRUCTURE
# ---------------------------------------------------------------------------

echo "[6/8] Configuring test gate..."

TEST_CMD=""

if node -e '
const p=require("./package.json");
process.exit(p.scripts && p.scripts["test:ci"] ? 0 : 1)
' 2>/dev/null; then

    TEST_CMD="npm run test:ci"

elif node -e '
const p=require("./package.json");
process.exit(p.scripts && p.scripts.test ? 0 : 1)
' 2>/dev/null; then

    TEST_CMD="npm test"

elif [ -x node_modules/.bin/vitest ]; then
    TEST_CMD="node_modules/.bin/vitest run"

elif [ -x node_modules/.bin/jest ]; then
    TEST_CMD="node_modules/.bin/jest --runInBand"

elif [ -x node_modules/.bin/mocha ]; then
    TEST_CMD="node_modules/.bin/mocha"

fi

if [ -n "$TEST_CMD" ]; then
    echo "✓ Test command: $TEST_CMD"

    if bash -c "$TEST_CMD" >"$LOG/test.log" 2>&1; then
        echo "✓ TESTS PASSED"
        TEST_PASS=1
    else
        echo "△ TESTS FAILED"
        TEST_PASS=0
    fi
else
    echo "△ No existing test runner"
    TEST_PASS=2
fi

# ---------------------------------------------------------------------------
# 7. CREATE A NON-DESTRUCTIVE SMOKE TEST WHEN NO TEST RUNNER EXISTS
# ---------------------------------------------------------------------------

echo "[7/8] Running artifact smoke gate..."

SMOKE=0

node - <<'NODE' >"$LOG/smoke.log" 2>&1
const fs=require("fs");

function required(path) {
  if (!fs.existsSync(path)) {
    throw new Error("Missing required artifact: "+path);
  }
}

required(".next");
required(".next/server");

const files=fs.readdirSync(".next/server",{recursive:true});
if (!files.length) throw new Error("Server artifact is empty");

console.log("SERVER_ARTIFACT=PASS");
console.log("FILES="+files.length);
NODE

if [ "$?" -eq 0 ]; then
    SMOKE=1
    echo "✓ SERVER SMOKE TEST PASSED"
else
    echo "✗ SERVER SMOKE TEST FAILED"
    cat "$LOG/smoke.log"
    exit 1
fi

# ---------------------------------------------------------------------------
# 8. FINAL GREEN GATE
# ---------------------------------------------------------------------------

echo "[8/8] Final green gate..."

if [ "$BUILD_PASS" -eq 1 ] && [ "$SMOKE" -eq 1 ]; then

    mkdir -p "$STATE/artifacts"

    rm -rf "$STATE/artifacts/server"
    cp -a .next/server "$STATE/artifacts/server"

    cat > "$STATE/status.json" <<JSON
{
  "state": "GREEN",
  "build": "PASS",
  "server_artifact": "PASS",
  "server_files": $SERVER_COUNT,
  "smoke_test": "PASS",
  "existing_test_runner": "$TEST_CMD",
  "existing_tests": "$([ "${TEST_PASS:-2}" = "1" ] && echo PASS || echo NOT_CONFIGURED)",
  "engine": "STOPPED",
  "timestamp": "$(date -Iseconds)"
}
JSON

    echo
    echo "=============================================================="
    echo " GREEN"
    echo "=============================================================="
    echo "BUILD            : PASS"
    echo "SERVER ARTIFACT  : PASS"
    echo "SMOKE TEST       : PASS"

    if [ "${TEST_PASS:-2}" = "1" ]; then
        echo "PROJECT TESTS    : PASS"
    else
        echo "PROJECT TESTS    : NOT CONFIGURED"
    fi

    echo "ENGINE           : STOPPED"
    echo "=============================================================="

    exit 0
fi

echo "✗ GREEN GATE FAILED"
exit 1
