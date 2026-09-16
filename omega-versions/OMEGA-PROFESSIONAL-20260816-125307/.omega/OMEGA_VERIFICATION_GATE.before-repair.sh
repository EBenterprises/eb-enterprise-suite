#!/data/data/com.termux/files/usr/bin/bash

ROOT="$HOME/omega"
cd "$ROOT" || exit 1

PASS=0
FAIL=0
WARN=0

pass() { printf 'PASS  %s\n' "$1"; PASS=$((PASS+1)); }
fail() { printf 'FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); }
warn() { printf 'WARN  %s\n' "$1"; WARN=$((WARN+1)); }

section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

echo "============================================================"
echo "              OMEGA® VERIFICATION GATE"
echo "============================================================"
echo "ROOT: $ROOT"
echo "DATE: $(date)"
echo

section "GATE 01 — FILESYSTEM"

[ -f package.json ] && pass "package.json" || fail "package.json missing"
[ -f package-lock.json ] && pass "package-lock.json" || fail "package-lock.json missing"
[ -f bin/omega.js ] && pass "CLI entrypoint" || fail "bin/omega.js missing"
[ -d src ] && pass "src/" || fail "src/ missing"
[ -d tests ] && pass "tests/" || fail "tests/ missing"
[ -d public ] && pass "public/" || fail "public/ missing"
[ -d data ] && pass "data/" || fail "data/ missing"

section "GATE 02 — CORE ARCHITECTURE"

CORE_FILES=(
  src/core/omega.js
  src/core/kernel.js
  src/core/errors.js
  src/core/events.js
  src/core/metrics.js
  src/core/parser.js
  src/core/registry.js
  src/core/state.js
  src/core/validate.js
  src/core/validation.js
)

for f in "${CORE_FILES[@]}"; do
  [ -f "$f" ] && pass "$f" || fail "$f"
done

section "GATE 03 — ARCHITECTURAL MODULES"

MODULE_DIRS=(
  agents
  app
  contracts
  engines
  governance
  intelligence
  learning
  memory
  observability
  orchestration
  orchestrator
  planning
  plugins
  runtime
  scheduler
  security
  telemetry
  verification
)

for d in "${MODULE_DIRS[@]}"; do
  [ -d "src/$d" ] && pass "src/$d/" || fail "src/$d/ missing"
done

section "GATE 04 — PACKAGE MANIFEST"

node - <<'NODE'
const fs = require("fs");

try {
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));

  console.log("name:", p.name);
  console.log("version:", p.version);
  console.log("type:", p.type);
  console.log("dependencies:", Object.keys(p.dependencies || {}).length);
  console.log("devDependencies:", Object.keys(p.devDependencies || {}).length);

  if (!p.name) process.exitCode = 1;
  if (!p.version) process.exitCode = 1;
  if (p.type !== "module") process.exitCode = 1;
} catch (e) {
  console.error(e.message);
  process.exitCode = 1;
}
NODE

if node -e 'const p=require("./package.json"); process.exit(p.name==="omega" && p.type==="module" ? 0 : 1)'; then
  pass "package manifest identity"
else
  fail "package manifest identity"
fi

section "GATE 05 — LOCKFILE INTEGRITY"

node - <<'NODE'
const fs = require("fs");

const p = JSON.parse(fs.readFileSync("package.json"));
const l = JSON.parse(fs.readFileSync("package-lock.json"));
const backup = fs.existsSync("package-lock.json.pre-repair")
  ? JSON.parse(fs.readFileSync("package-lock.json.pre-repair"))
  : null;

console.log("package.json version:", p.version);
console.log("package-lock version:", l.version);
console.log("lockfileVersion:", l.lockfileVersion);

if (l.packages?.[""]) {
  console.log("lock root version:", l.packages[""].version);
  console.log(
    "lock dependencies:",
    JSON.stringify(l.packages[""].dependencies || {}, null, 2)
  );
  console.log(
    "lock devDependencies:",
    JSON.stringify(l.packages[""].devDependencies || {}, null, 2)
  );
}

if (backup?.packages?.[""]) {
  console.log(
    "BACKUP lock root:",
    JSON.stringify(backup.packages[""], null, 2)
  );
}
NODE

if node - <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json"));
const l = JSON.parse(fs.readFileSync("package-lock.json"));

process.exit(
  l.name === p.name &&
  l.packages?.[""]?.name === p.name &&
  l.packages?.[""]?.version === p.version
    ? 0 : 1
);
NODE
then
  pass "package.json ↔ package-lock root consistency"
else
  fail "package.json ↔ package-lock root consistency"
fi

section "GATE 06 — NODE ENVIRONMENT"

node --version
npm --version

node -e 'process.exit(process.versions.node ? 0 : 1)' \
  && pass "Node.js executable" \
  || fail "Node.js executable"

npm --version >/dev/null 2>&1 \
  && pass "npm executable" \
  || fail "npm executable"

section "GATE 07 — INSTALLED DEPENDENCIES"

if [ -d node_modules ]; then
  pass "node_modules exists"
else
  fail "node_modules missing"
fi

if [ -x node_modules/.bin/next ]; then
  pass "Next CLI installed"
  node_modules/.bin/next --version
else
  fail "Next CLI missing"
fi

for pkg in next react react-dom; do
  if [ -f "node_modules/$pkg/package.json" ]; then
    V=$(node -p "require('./node_modules/$pkg/package.json').version")
    pass "$pkg installed ($V)"
  else
    fail "$pkg missing"
  fi
done

section "GATE 08 — CLI IMPORT INTEGRITY"

if node --input-type=module -e 'import("./src/core/omega.js").then(()=>process.exit(0)).catch(e=>{console.error(e.message);process.exit(1)})'
then
  pass "src/core/omega.js imports"
else
  fail "src/core/omega.js import"
fi

if node --input-type=module -e 'import("./bin/omega.js").then(()=>process.exit(0)).catch(e=>{console.error(e.message);process.exit(1)})'
then
  pass "bin/omega.js imports"
else
  fail "bin/omega.js import"
fi

section "GATE 09 — OMEGA CLI"

for cmd in status capabilities metrics help; do
  echo
  echo "--- omega $cmd ---"

  if timeout 30 node bin/omega.js "$cmd" >.omega.omega.omega.omega/tmp/omega-gate-"$cmd".out 2>.omega.omega.omega.omega/tmp/omega-gate-"$cmd".err
  then
    pass "CLI command: $cmd"
    head -40 .omega.omega.omega.omega/tmp/omega-gate-"$cmd".out
  else
    fail "CLI command: $cmd"
    cat .omega.omega.omega.omega/tmp/omega-gate-"$cmd".err
  fi
done

section "GATE 10 — SOURCE SYNTAX"

SYNTAX_FAIL=0

while IFS= read -r -d '' f; do
  if ! node --check "$f" >/dev/null 2>&1; then
    fail "syntax: $f"
    node --check "$f" 2>&1 | head -10
    SYNTAX_FAIL=1
  fi
done < <(find src bin -type f -name '*.js' -print0)

[ "$SYNTAX_FAIL" -eq 0 ] \
  && pass "all JS source syntax" \
  || true

section "GATE 11 — TEST DISCOVERY"

TEST_COUNT=$(find tests -type f -name '*.test.js' | wc -l | tr -d ' ')

echo "Test files: $TEST_COUNT"

if [ "$TEST_COUNT" -gt 0 ]; then
  pass "test suite discovered"
else
  fail "no tests discovered"
fi

find tests -type f -name '*.test.js' -print | sort

section "GATE 12 — TEST EXECUTION"

if npm test > .omega.omega.omega.omega/tmp/omega-test-output.txt 2>&1; then
  pass "npm test"
else
  fail "npm test"
fi

echo
echo "--- TEST OUTPUT ---"
cat .omega.omega.omega.omega/tmp/omega-test-output.txt

section "GATE 13 — NEXT CONFIGURATION"

for f in next.config.mjs jsconfig.json postcss.config.mjs; do
  [ -f "$f" ] && pass "$f" || fail "$f"
done

section "GATE 14 — NEXT BUILD"

if [ -x node_modules/.bin/next ]; then
  if npm exec next build > .omega.omega/tmp/omega-next-build.txt 2>&1; then
    pass "Next production build"
  else
    fail "Next production build"
  fi

  echo
  echo "--- NEXT BUILD OUTPUT ---"
  tail -100 .omega.omega/tmp/omega-next-build.txt
else
  fail "Next build unavailable because Next CLI is missing"
fi

section "GATE 15 — DATA / STATE"

for f in \
  data/omega-memory.json \
  data/omega-state.json \
  data/versions.json
do
  if [ -f "$f" ]; then
    if node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" >/dev/null 2>&1; then
      pass "valid JSON: $f"
    else
      fail "invalid JSON: $f"
    fi
  else
    fail "missing: $f"
  fi
done

section "GATE 16 — CONTRACT TESTS"

for f in tests/contracts/*.test.js; do
  if [ -f "$f" ]; then
    echo "CONTRACT: $f"
  fi
done

section "GATE 17 — GIT"

if [ -d .git ]; then
  pass "Git repository"
  echo "branch: $(git branch --show-current)"
  git status --short
else
  warn "Git repository not initialized"
fi

section "FINAL VERIFICATION"

echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "WARN: $WARN"
echo

if [ "$FAIL" -eq 0 ]; then
  echo "============================================================"
  echo "                 VERIFICATION GATE: PASS"
  echo "============================================================"
  exit 0
else
  echo "============================================================"
  echo "                 VERIFICATION GATE: FAIL"
  echo "============================================================"
  echo
  echo "OMEGA® is NOT certified until all required FAIL gates are resolved."
  exit 1
fi
