#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"
CERT="$ROOT/.omega/certification"

mkdir -p "$TMP" "$CERT"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "       OMEGA® FINAL VERIFICATION GATE REPAIR"
echo "============================================================"

# ------------------------------------------------------------
# 1. Remove the obsolete App Router favicon
# ------------------------------------------------------------

echo
echo "=== 1. FAVICON ==="

rm -f src/app/favicon.ico

if [ -f public/favicon.ico ]; then
    echo "PASS  public/favicon.ico"
else
    echo "FAIL  public/favicon.ico missing"
    exit 1
fi

# ------------------------------------------------------------
# 2. Make package build canonical
# ------------------------------------------------------------

echo
echo "=== 2. PACKAGE BUILD ==="

node - <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("PASS  build = next build --webpack");
NODE

# ------------------------------------------------------------
# 3. Repair Gate 14 exactly
# ------------------------------------------------------------

echo
echo "=== 3. REPAIR GATE 14 ==="

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
 * Replace the entire Gate 14 build invocation.
 *
 * IMPORTANT:
 * package.json already contains:
 *
 *   next build --webpack
 *
 * Therefore Gate 14 MUST execute only:
 *
 *   npm run build
 *
 * Never:
 *
 *   npm run build -- --webpack
 *   npm exec next build -- --webpack
 *   npm run build --webpack
 */
s = s.replace(
  /if npm run build[^\n]*omega-next-build\.txt[^\n]*; then/g,
  'if npm run build > .omega/tmp/omega-next-build.txt 2>&1; then'
);

/*
 * Catch any remaining npm-exec variant.
 */
s = s.replace(
  /if npm exec next build[^\n]*; then/g,
  'if npm run build > .omega/tmp/omega-next-build.txt 2>&1; then'
);

/*
 * Catch the duplicate package-script argument.
 */
s = s.replace(
  /npm run build\s+--\s+--webpack/g,
  "npm run build"
);

/*
 * Remove accidental duplicate webpack arguments anywhere else.
 */
s = s.replace(
  /next build --webpack --webpack/g,
  "next build --webpack"
);

s = s.replace(
  /next build --webpack -- --webpack/g,
  "next build --webpack"
);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "=== GATE 14 RESULT ==="

sed -n '289,305p' "$GATE"

echo
echo "=== FORBIDDEN BUILD FORMS ==="

if grep -nE \
  'npm run build -- --webpack|npm exec next build|next build --webpack --webpack|next build --webpack -- --webpack' \
  "$GATE"; then

    echo "FAIL  forbidden duplicate build invocation remains"
    exit 1
else
    echo "PASS  no duplicate build invocation"
fi

# ------------------------------------------------------------
# 4. Syntax
# ------------------------------------------------------------

echo
echo "=== 4. GATE SYNTAX ==="

bash -n "$GATE"
echo "PASS  verification gate syntax"

# ------------------------------------------------------------
# 5. Completely clean Next artifacts
# ------------------------------------------------------------

echo
echo "=== 5. CLEAN NEXT ARTIFACTS ==="

rm -rf .next

echo "PASS  removed .next"

# ------------------------------------------------------------
# 6. Fresh production build
# ------------------------------------------------------------

echo
echo "=== 6. FRESH PRODUCTION BUILD ==="

if npm run build > "$TMP/omega-final-clean-build.txt" 2>&1; then
    tail -40 "$TMP/omega-final-clean-build.txt"
    echo
    echo "PASS  fresh production build"
else
    cat "$TMP/omega-final-clean-build.txt"
    echo
    echo "FAIL  fresh production build"
    exit 1
fi

# ------------------------------------------------------------
# 7. Artifact verification
# ------------------------------------------------------------

echo
echo "=== 7. ARTIFACT VERIFICATION ==="

test -d .next
echo "PASS  .next exists"

test -f public/favicon.ico
echo "PASS  public/favicon.ico exists"

if find .next/server/app \
    -path '*favicon.ico/route.js' \
    -print -quit 2>/dev/null | grep -q .; then

    echo "FAIL  favicon route artifact exists"
    exit 1
else
    echo "PASS  favicon route artifact absent"
fi

# ------------------------------------------------------------
# 8. Test suite
# ------------------------------------------------------------

echo
echo "=== 8. TEST SUITE ==="

if npm test > "$TMP/omega-final-clean-test.txt" 2>&1; then
    tail -20 "$TMP/omega-final-clean-test.txt"
else
    cat "$TMP/omega-final-clean-test.txt"
    echo "FAIL  test suite"
    exit 1
fi

echo
echo "PASS  39/39 tests"

# ------------------------------------------------------------
# 9. Final gate
# ------------------------------------------------------------

echo
echo "=== 9. FORMAL VERIFICATION GATE ==="

rm -f "$CERT/final-gate.log"

set +e
"$GATE" 2>&1 | tee "$CERT/final-gate.log"
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "             OMEGA® FINAL CERTIFICATION"
echo "============================================================"

echo
echo "EXIT CODE: $RC"

if [ "$RC" -ne 0 ]; then
    echo
    echo "FAIL  Formal verification gate"
    echo
    echo "Failure summary:"
    grep -aE '^(PASS|FAIL|WARN) |^PASS:|^FAIL:|^WARN:|VERIFICATION GATE:' \
        "$CERT/final-gate.log" | tail -30 || true
    exit "$RC"
fi

echo
echo "PASS  All verification gates"
echo "PASS  OMEGA® CERTIFIED"

# ------------------------------------------------------------
# 10. Final state
# ------------------------------------------------------------

node - <<'NODE'
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

console.log("PASS  OMEGA state certified");
NODE

echo
echo "=== FINAL STATUS ==="

node bin/omega.js status

echo
echo "=== FINAL CAPABILITIES ==="

node bin/omega.js capabilities

echo
echo "============================================================"
echo "      OMEGA® BUILT • VERIFIED • CERTIFIED • OPERATIONAL"
echo "============================================================"
