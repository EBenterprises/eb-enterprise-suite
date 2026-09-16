#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"
CERT="$ROOT/.omega/certification"
LOG="$CERT/final-gate.log"

mkdir -p "$TMP" "$CERT"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "       OMEGA® FINAL FAILURE RESOLUTION"
echo "============================================================"

# ============================================================
# 1. FAVICON — definitive App Router repair
# ============================================================

echo
echo "=== 1. FAVICON ==="

if [ -f "src/app/favicon.ico" ]; then
    cp -f "src/app/favicon.ico" "public/favicon.ico"
    rm -f "src/app/favicon.ico"
fi

if [ -f "public/favicon.ico" ] && [ ! -e "src/app/favicon.ico" ]; then
    echo "PASS  favicon served from public/"
else
    echo "FAIL  favicon placement"
    exit 1
fi

# ============================================================
# 2. PACKAGE BUILD — exactly ONE webpack argument
# ============================================================

echo
echo "=== 2. PACKAGE BUILD COMMAND ==="

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("PASS  package.json build = next build --webpack");
NODE

# ============================================================
# 3. REWRITE GATE 14 — deterministic
# ============================================================

echo
echo "=== 3. REPAIR VERIFICATION GATE ==="

node "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[1];
let s = fs.readFileSync(file, "utf8");

/*
 * Normalize OMEGA temporary paths.
 */
s = s.replace(
  /(?:\.omega)+\/tmp\//g,
  ".omega/tmp/"
);

/*
 * Locate Gate 14.
 */
const marker = 'section "GATE 14 — NEXT BUILD"';
const start = s.indexOf(marker);

if (start === -1) {
  throw new Error("GATE 14 section not found");
}

/*
 * Locate the next section after Gate 14.
 */
const next = s.indexOf(
  '\nsection "GATE 15',
  start
);

if (next === -1) {
  throw new Error("GATE 15 section not found");
}

/*
 * Replace the entire Gate 14 implementation.
 *
 * IMPORTANT:
 *
 * npm run build
 *
 * is intentional.
 *
 * package.json already contains:
 *
 * next build --webpack
 *
 * Therefore:
 *
 * npm run build -- --webpack
 *
 * would incorrectly produce:
 *
 * next build --webpack --webpack
 */
const gate14 = `section "GATE 14 — NEXT BUILD"

if [ -x node_modules/.bin/next ]; then

  rm -rf .next

  if npm run build > .omega/tmp/omega-next-build.txt 2>&1; then
    pass "Next production build"
  else
    fail "Next production build"
  fi

  echo
  echo "--- NEXT BUILD OUTPUT ---"
  tail -100 .omega/tmp/omega-next-build.txt

else
  fail "Next CLI installed"
fi
`;

s =
  s.slice(0, start) +
  gate14 +
  s.slice(next);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo "PASS  Gate 14 rewritten"

# ============================================================
# 4. VERIFY THERE IS NO DUPLICATE WEBPACK ARGUMENT
# ============================================================

echo
echo "=== 4. GATE 14 AUDIT ==="

sed -n '/GATE 14 — NEXT BUILD/,/GATE 15/p' "$GATE"

if grep -nE \
  'npm run build[[:space:]]+--[[:space:]]+--webpack|npm exec next build' \
  "$GATE"; then

    echo
    echo "FAIL  duplicate/incorrect Next invocation remains"
    exit 1
fi

echo "PASS  no npm exec build invocation"
echo "PASS  no duplicated --webpack forwarding"

# ============================================================
# 5. SHELL SYNTAX
# ============================================================

echo
echo "=== 5. GATE SYNTAX ==="

bash -n "$GATE"

echo "PASS  verification gate shell syntax"

# ============================================================
# 6. CLEAN ALL NEXT ARTIFACTS
# ============================================================

echo
echo "=== 6. CLEAN NEXT ==="

rm -rf .next

echo "PASS  removed stale .next"

# ============================================================
# 7. DIRECT PRODUCTION BUILD
# ============================================================

echo
echo "=== 7. DIRECT PRODUCTION BUILD ==="

if npm run build > "$TMP/omega-final-build.txt" 2>&1; then
    tail -50 "$TMP/omega-final-build.txt"
    echo
    echo "PASS  direct production build"
else
    cat "$TMP/omega-final-build.txt"
    echo
    echo "FAIL  direct production build"
    exit 1
fi

# ============================================================
# 8. ARTIFACT AUDIT
# ============================================================

echo
echo "=== 8. ARTIFACT AUDIT ==="

test -d ".next" || {
    echo "FAIL  .next missing"
    exit 1
}

test -f "public/favicon.ico" || {
    echo "FAIL  public/favicon.ico missing"
    exit 1
}

if find ".next/server/app" \
    -path "*favicon.ico/route.js" \
    -print -quit 2>/dev/null | grep -q .; then

    echo "FAIL  favicon route artifact exists"
    exit 1
fi

echo "PASS  .next exists"
echo "PASS  public/favicon.ico exists"
echo "PASS  no favicon App Router route"

# ============================================================
# 9. TEST SUITE
# ============================================================

echo
echo "=== 9. TEST SUITE ==="

if npm test > "$TMP/omega-final-test.txt" 2>&1; then
    tail -25 "$TMP/omega-final-test.txt"
else
    cat "$TMP/omega-final-test.txt"
    echo "FAIL  test suite"
    exit 1
fi

PASS_COUNT="$(grep -E 'ℹ pass' "$TMP/omega-final-test.txt" | tail -1 | awk '{print $3}')"
FAIL_COUNT="$(grep -E 'ℹ fail' "$TMP/omega-final-test.txt" | tail -1 | awk '{print $3}')"

if [ "$PASS_COUNT" = "39" ] && [ "$FAIL_COUNT" = "0" ]; then
    echo "PASS  39/39 tests"
else
    echo "FAIL  expected 39/39 tests"
    exit 1
fi

# ============================================================
# 10. FORMAL VERIFICATION
# ============================================================

echo
echo "=== 10. FORMAL VERIFICATION GATE ==="

rm -f "$LOG"

set +e
"$GATE" 2>&1 | tee "$LOG"
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "          OMEGA® FINAL VERIFICATION RESULT"
echo "============================================================"

echo
echo "EXIT CODE: $RC"

if [ "$RC" -ne 0 ]; then
    echo
    echo "FAIL  FORMAL VERIFICATION"
    echo
    echo "Failure summary:"
    grep -aE '^FAIL|VERIFICATION GATE:' "$LOG" | tail -30 || true
    exit "$RC"
fi

# ============================================================
# 11. FINAL STATE — ONLY AFTER REAL PASS
# ============================================================

echo
echo "=== 11. FINAL OMEGA STATE ==="

node <<'NODE'
const fs = require("fs");

const file = "data/omega-state.json";

let state = {};

try {
  state = JSON.parse(fs.readFileSync(file, "utf8"));
} catch {}

state.identity ??= {};

state.identity.name = "OMEGA";
state.identity.status = "operational";
state.identity.initialized = true;
state.identity.certified = true;
state.identity.certifiedAt = new Date().toISOString();

fs.writeFileSync(
  file,
  JSON.stringify(state, null, 2) + "\n"
);

console.log("PASS  OMEGA identity/state finalized");
NODE

# ============================================================
# 12. FINAL REPORT
# ============================================================

echo
echo "=== 12. FINAL STATUS ==="

node bin/omega.js status

echo
echo "=== CAPABILITIES ==="

node bin/omega.js capabilities

echo
echo "=== TESTS ==="

grep -aE 'ℹ pass|ℹ fail' "$TMP/omega-final-test.txt" | tail -2

echo
echo "=== BUILD ==="

test -d .next && echo "PASS  production artifact"

echo
echo "=== CERTIFICATION COUNTS ==="

grep -aE '^PASS:|^FAIL:|^WARN:|VERIFICATION GATE:' "$LOG" | tail -10

echo
echo "============================================================"
echo "       OMEGA® INITIALIZED"
echo "       OMEGA® BUILT"
echo "       OMEGA® VERIFIED"
echo "       OMEGA® CERTIFIED"
echo "============================================================"

exit 0
