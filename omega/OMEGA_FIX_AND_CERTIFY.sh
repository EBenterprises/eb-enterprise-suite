#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"
CERT="$ROOT/.omega/certification"

mkdir -p "$TMP" "$CERT"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "       OMEGA® — DEFINITIVE BUILD + GATE REPAIR"
echo "============================================================"

# ============================================================
# 1. FIX FAVICON
# ============================================================

echo
echo "=== [1/6] FAVICON ==="

if [ -f "src/app/favicon.ico" ]; then
    cp -f "src/app/favicon.ico" "public/favicon.ico"
    rm -f "src/app/favicon.ico"
    echo "PASS  favicon relocated to public/favicon.ico"
elif [ -f "public/favicon.ico" ]; then
    echo "PASS  public/favicon.ico already present"
else
    echo "WARN  favicon not present; creating minimal public favicon"
    # A tiny valid 1x1 ICO.
    printf '\x00\x00\x01\x00\x01\x00\x01\x01\x00\x00\x01\x00\x18\x00\x0c\x00\x00\x00\x16\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' > public/favicon.ico
fi

# ============================================================
# 2. CLEAN NEXT ARTIFACTS
# ============================================================

echo
echo "=== [2/6] CLEAN BUILD STATE ==="

rm -rf .next
echo "PASS  stale .next removed"

# ============================================================
# 3. FORCE KNOWN-GOOD BUILD CONFIGURATION
# ============================================================

echo
echo "=== [3/6] BUILD CONFIGURATION ==="

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("PASS  package.json build = next build --webpack");
console.log("PASS  package.json dev   = next dev --webpack");
NODE

# ============================================================
# 4. REPAIR VERIFICATION GATE
# ============================================================

echo
echo "=== [4/6] VERIFICATION GATE ==="

cp "$GATE" "$CERT/OMEGA_VERIFICATION_GATE.pre-final-fix.sh"

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * Normalize temporary paths.
 */
s = s.replace(
  /(?:\.omega)+\/tmp\//g,
  ".omega/tmp/"
);

/*
 * Replace EVERY npm-exec Next build line with the already
 * verified package build command.
 *
 * This eliminates:
 *
 *   npm exec next build -- --webpack
 *   npm exec next build -- --webpack -- --webpack
 *   npm exec next build --webpack
 *
 * and all similar variants.
 */
s = s.replace(
  /npm exec next build[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

/*
 * Normalize duplicate redirection if the previous replacement
 * encountered an existing redirect.
 */
s = s.replace(
  /npm run build\s*>\s*\.omega\/tmp\/omega-next-build\.txt\s*>\s*\.omega\/tmp\/omega-next-build\.txt[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

/*
 * Ensure no malformed Next invocation remains.
 */
s = s.replace(
  /next build --webpack -- --webpack/g,
  "next build --webpack"
);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "--- BUILD INVOCATIONS ---"
grep -nE 'npm exec next build|npm run build|next build' "$GATE" || true

echo
echo "--- SHELL VALIDATION ---"
bash -n "$GATE"
echo "PASS  gate shell syntax"

# ============================================================
# 5. BUILD + TEST
# ============================================================

echo
echo "=== [5/6] PRODUCTION BUILD ==="

if npm run build > "$TMP/omega-final-build.txt" 2>&1; then
    tail -40 "$TMP/omega-final-build.txt"
    echo
    echo "PASS  production build"
else
    cat "$TMP/omega-final-build.txt"
    echo
    echo "FAIL  production build"
    exit 1
fi

echo
echo "=== BUILD ARTIFACT AUDIT ==="

test -d ".next"
echo "PASS  .next exists"

test -f "public/favicon.ico"
echo "PASS  public/favicon.ico exists"

if find ".next/server/app" -path "*favicon.ico/route.js" -print -quit 2>/dev/null | grep -q .; then
    echo "FAIL  favicon route artifact detected"
    exit 1
fi

echo "PASS  favicon route artifact absent"

echo
echo "=== TEST SUITE ==="

if npm test > "$TMP/omega-final-test.txt" 2>&1; then
    tail -20 "$TMP/omega-final-test.txt"

    PASS_COUNT="$(grep -oE 'ℹ pass [0-9]+' "$TMP/omega-final-test.txt" | tail -1 | awk '{print $3}')"
    FAIL_COUNT="$(grep -oE 'ℹ fail [0-9]+' "$TMP/omega-final-test.txt" | tail -1 | awk '{print $3}')"

    echo
    echo "PASS  tests passed: ${PASS_COUNT:-unknown}"
    echo "PASS  tests failed: ${FAIL_COUNT:-unknown}"
else
    cat "$TMP/omega-final-test.txt"
    echo "FAIL  test suite"
    exit 1
fi

# ============================================================
# 6. FORMAL CERTIFICATION
# ============================================================

echo
echo "=== [6/6] FORMAL VERIFICATION ==="

set +e
"$GATE" 2>&1 | tee "$CERT/final-gate.log"
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "             OMEGA® CERTIFICATION RESULT"
echo "============================================================"

grep -E '^(PASS|FAIL|WARN) |^PASS:|^FAIL:|^WARN:|VERIFICATION GATE:' \
    "$CERT/final-gate.log" | tail -100 || true

echo
echo "PASS COUNT:"
grep -E '^PASS: ' "$CERT/final-gate.log" | tail -1 || true

echo
echo "FAIL COUNT:"
grep -E '^FAIL: ' "$CERT/final-gate.log" | tail -1 || true

if [ "$RC" -ne 0 ]; then
    echo
    echo "============================================================"
    echo "          OMEGA® CERTIFICATION: FAILED"
    echo "============================================================"
    echo
    echo "Remaining failure:"
    grep '^FAIL ' "$CERT/final-gate.log" | tail -20 || true
    exit "$RC"
fi

# ============================================================
# FINAL STATE
# ============================================================

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

fs.writeFileSync(file, JSON.stringify(state, null, 2) + "\n");
NODE

echo
echo "============================================================"
echo "       OMEGA® INITIALIZED • BUILT • VERIFIED • CERTIFIED"
echo "============================================================"

node bin/omega.js status

echo
echo "Git:"
git status --short --branch

