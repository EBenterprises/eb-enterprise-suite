#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"

mkdir -p "$CERT" "$TMP"

echo "============================================================"
echo "       OMEGA® — CLEAN CERTIFICATION REBUILD"
echo "============================================================"

echo
echo "=== BACKUP CURRENT GATE ==="

if [ -f "$GATE" ]; then
    cp -f "$GATE" \
        "$CERT/OMEGA_VERIFICATION_GATE.before-clean-rebuild.$(date +%Y%m%d-%H%M%S).sh"
    echo "PASS  existing gate backed up"
fi

echo
echo "=== REPAIR PACKAGE BUILD CONFIGURATION ==="

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("PASS  build = next build --webpack");
console.log("PASS  dev   = next dev --webpack");
NODE

echo
echo "=== REPAIR FAVICON ==="

if [ -f "src/app/favicon.ico" ] && [ ! -f "public/favicon.ico" ]; then
    cp "src/app/favicon.ico" "public/favicon.ico"
fi

if [ -f "src/app/favicon.ico" ]; then
    rm -f "src/app/favicon.ico"
fi

test -f "public/favicon.ico"
echo "PASS  public/favicon.ico"

echo
echo "=== CLEAN NEXT ==="

rm -rf .next
echo "PASS  .next removed"

echo
echo "=== BUILD ==="

npm run build > "$TMP/clean-cert-build.txt" 2>&1
cat "$TMP/clean-cert-build.txt"

test -d .next
echo "PASS  production artifact"

echo
echo "=== TESTS ==="

npm test > "$TMP/clean-cert-test.txt" 2>&1
tail -30 "$TMP/clean-cert-test.txt"

grep -q "ℹ pass 39" "$TMP/clean-cert-test.txt"
grep -q "ℹ fail 0" "$TMP/clean-cert-test.txt"

echo "PASS  39/39 tests"

echo
echo "=== GENERATE CLEAN VERIFICATION GATE ==="

cat > "$GATE" <<'GATEEOF'
#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
    echo "PASS  $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "FAIL  $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
    echo "WARN  $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

check_file() {
    if [ -f "$1" ]; then
        pass "$1"
    else
        fail "$1"
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        pass "$1"
    else
        fail "$1"
    fi
}

echo "============================================================"
echo "              OMEGA® VERIFICATION GATE"
echo "============================================================"

echo "ROOT: $ROOT"
echo "DATE: $(date)"

echo
echo "============================================================"
echo "GATE 01 — FILESYSTEM"
echo "============================================================"

check_file package.json
check_file package-lock.json
check_file bin/omega.js
check_dir src
check_dir tests
check_dir public
check_dir data

echo
echo "============================================================"
echo "GATE 02 — CORE ARCHITECTURE"
echo "============================================================"

for f in \
    src/core/omega.js \
    src/core/kernel.js \
    src/core/errors.js \
    src/core/events.js \
    src/core/metrics.js \
    src/core/parser.js \
    src/core/registry.js \
    src/core/state.js \
    src/core/validate.js \
    src/core/validation.js
do
    check_file "$f"
done

echo
echo "============================================================"
echo "GATE 03 — ARCHITECTURAL MODULES"
echo "============================================================"

for d in \
    src/agents \
    src/app \
    src/contracts \
    src/engines \
    src/governance \
    src/intelligence \
    src/learning \
    src/memory \
    src/observability \
    src/orchestration \
    src/orchestrator \
    src/planning \
    src/plugins \
    src/runtime \
    src/scheduler \
    src/security \
    src/telemetry \
    src/verification
do
    check_dir "$d"
done

echo
echo "============================================================"
echo "GATE 04 — PACKAGE MANIFEST"
echo "============================================================"

if node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json"));

if (p.name !== "omega") process.exit(1);
if (p.version !== "1.0.0") process.exit(1);
if (p.type !== "module") process.exit(1);
if (!p.dependencies) process.exit(1);

console.log("name:", p.name);
console.log("version:", p.version);
console.log("type:", p.type);
console.log("dependencies:", Object.keys(p.dependencies).length);
console.log("devDependencies:", Object.keys(p.devDependencies || {}).length);
NODE
then
    pass "package manifest identity"
else
    fail "package manifest identity"
fi

echo
echo "============================================================"
echo "GATE 05 — LOCKFILE INTEGRITY"
echo "============================================================"

if node <<'NODE'
const fs = require("fs");

const p = JSON.parse(fs.readFileSync("package.json"));
const l = JSON.parse(fs.readFileSync("package-lock.json"));

if (p.name !== l.name) process.exit(1);
if (p.version !== l.version) process.exit(1);
if (l.lockfileVersion !== 3) process.exit(1);
if (!l.packages || !l.packages[""]) process.exit(1);
if (l.packages[""].version !== p.version) process.exit(1);

console.log("package.json version:", p.version);
console.log("package-lock version:", l.version);
console.log("lockfileVersion:", l.lockfileVersion);
console.log("lock root version:", l.packages[""].version);
NODE
then
    pass "package.json ↔ package-lock root consistency"
else
    fail "package.json ↔ package-lock root consistency"
fi

echo
echo "============================================================"
echo "GATE 06 — NODE ENVIRONMENT"
echo "============================================================"

node --version
npm --version

if command -v node >/dev/null 2>&1; then
    pass "Node.js executable"
else
    fail "Node.js executable"
fi

if command -v npm >/dev/null 2>&1; then
    pass "npm executable"
else
    fail "npm executable"
fi

echo
echo "============================================================"
echo "GATE 07 — INSTALLED DEPENDENCIES"
echo "============================================================"

check_dir node_modules

if [ -x node_modules/.bin/next ]; then
    pass "Next CLI installed"
else
    fail "Next CLI installed"
fi

for package in next react react-dom; do
    if node -e "require('./node_modules/$package/package.json')" >/dev/null 2>&1; then
        VERSION="$(node -p "require('./node_modules/$package/package.json').version")"
        echo "$package: $VERSION"
        pass "$package installed"
    else
        fail "$package installed"
    fi
done

echo
echo "============================================================"
echo "GATE 08 — CLI IMPORT INTEGRITY"
echo "============================================================"

if node --input-type=module <<'NODE'
await import("./src/core/omega.js");
NODE
then
    pass "src/core/omega.js imports"
else
    fail "src/core/omega.js imports"
fi

if node --input-type=module <<'NODE'
await import("./bin/omega.js");
NODE
then
    pass "bin/omega.js imports"
else
    fail "bin/omega.js imports"
fi

echo
echo "============================================================"
echo "GATE 09 — OMEGA CLI"
echo "============================================================"

if node bin/omega.js status >/dev/null 2>&1; then
    pass "CLI command: status"
else
    fail "CLI command: status"
fi

if node bin/omega.js capabilities >/dev/null 2>&1; then
    pass "CLI command: capabilities"
else
    fail "CLI command: capabilities"
fi

if node bin/omega.js metrics >/dev/null 2>&1; then
    pass "CLI command: metrics"
else
    fail "CLI command: metrics"
fi

if node bin/omega.js help >/dev/null 2>&1; then
    pass "CLI command: help"
else
    fail "CLI command: help"
fi

echo
echo "============================================================"
echo "GATE 10 — SOURCE SYNTAX"
echo "============================================================"

SYNTAX_FAIL=0

while IFS= read -r f; do
    if ! node --check "$f" >/dev/null 2>&1; then
        echo "FAIL  syntax: $f"
        SYNTAX_FAIL=1
    fi
done < <(find src bin -type f -name "*.js" -print)

if [ "$SYNTAX_FAIL" -eq 0 ]; then
    pass "all JS source syntax"
else
    fail "all JS source syntax"
fi

echo
echo "============================================================"
echo "GATE 11 — TEST DISCOVERY"
echo "============================================================"

TEST_COUNT="$(find tests -type f -name "*.test.js" | wc -l | tr -d ' ')"
echo "Test files: $TEST_COUNT"

if [ "$TEST_COUNT" -gt 0 ]; then
    pass "test suite discovered"
else
    fail "test suite discovered"
fi

echo
echo "============================================================"
echo "GATE 12 — TEST EXECUTION"
echo "============================================================"

TEST_OUTPUT=".omega/tmp/omega-gate-test-output.txt"
mkdir -p .omega/tmp

if npm test > "$TEST_OUTPUT" 2>&1; then
    pass "npm test"
else
    fail "npm test"
fi

tail -25 "$TEST_OUTPUT"

echo
echo "============================================================"
echo "GATE 13 — NEXT CONFIGURATION"
echo "============================================================"

check_file next.config.mjs
check_file jsconfig.json
check_file postcss.config.mjs

echo
echo "============================================================"
echo "GATE 14 — NEXT BUILD"
echo "============================================================"

BUILD_OUTPUT=".omega/tmp/omega-gate-next-build.txt"

rm -rf .next

if npm run build > "$BUILD_OUTPUT" 2>&1; then
    pass "Next production build"
else
    fail "Next production build"
    echo
    echo "--- NEXT BUILD OUTPUT ---"
    cat "$BUILD_OUTPUT"
fi

echo
echo "============================================================"
echo "GATE 15 — DATA / STATE"
echo "============================================================"

for f in \
    data/omega-memory.json \
    data/omega-state.json \
    data/versions.json
do
    if [ -f "$f" ] && node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" >/dev/null 2>&1; then
        pass "valid JSON: $f"
    else
        fail "valid JSON: $f"
    fi
done

echo
echo "============================================================"
echo "GATE 16 — CONTRACT TESTS"
echo "============================================================"

for f in \
    tests/contracts/execution-integrity.test.js \
    tests/contracts/integrity.test.js \
    tests/contracts/public-api.test.js
do
    if [ -f "$f" ]; then
        echo "CONTRACT: $f"
    else
        fail "contract: $f"
    fi
done

echo
echo "============================================================"
echo "GATE 17 — GIT"
echo "============================================================"

if [ -d .git ]; then
    pass "Git repository"
    echo "branch: $(git branch --show-current)"
else
    fail "Git repository"
fi

echo
echo "============================================================"
echo "             OMEGA® VERIFICATION SUMMARY"
echo "============================================================"

echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo "WARN: $WARN_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "VERIFICATION GATE: PASS"
    exit 0
else
    echo "VERIFICATION GATE: FAIL"
    exit 1
fi
GATEEOF

chmod +x "$GATE"

echo "PASS  clean verification gate generated"

echo
echo "=== VALIDATE GATE PARSER ==="

bash -n "$GATE"
echo "PASS  gate shell syntax"

echo
echo "=== VERIFY BUILD INVOCATION ==="

grep -nE 'npm run build|next build|npm exec next build' "$GATE"

if grep -nE 'npm run build[[:space:]]+--|next build.*--webpack.*--webpack' "$GATE"; then
    echo
    echo "FAIL  malformed/double build invocation detected"
    exit 1
fi

echo "PASS  no duplicate webpack invocation"

echo
echo "=== RUN CLEAN VERIFICATION GATE ==="

set +e
"$GATE" 2>&1 | tee "$CERT/clean-gate.log"
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "             OMEGA® FINAL CERTIFICATION"
echo "============================================================"

if [ "$RC" -eq 0 ]; then
    echo
    echo "PASS  ALL VERIFICATION GATES"
    echo "PASS  OMEGA® CERTIFIED"
else
    echo
    echo "FAIL  CERTIFICATION"
    echo
    grep '^FAIL  ' "$CERT/clean-gate.log" || true
    exit "$RC"
fi

echo
echo "=== FINAL CLI STATUS ==="
node bin/omega.js status

echo
echo "=== FINAL CAPABILITIES ==="
node bin/omega.js capabilities

echo
echo "=== FINAL ARTIFACT ==="
test -d .next
echo "PASS  .next"

echo
echo "============================================================"
echo "       OMEGA® INITIALIZED • BUILT • VERIFIED • CERTIFIED"
echo "============================================================"
