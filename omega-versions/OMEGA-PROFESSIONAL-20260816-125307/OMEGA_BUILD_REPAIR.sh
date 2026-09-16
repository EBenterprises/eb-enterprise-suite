#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"

mkdir -p "$TMP"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "          OMEGA® PRODUCTION BUILD REPAIR"
echo "============================================================"

# ------------------------------------------------------------
# 1. Repair favicon placement
# ------------------------------------------------------------

echo
echo "=== 1. FAVICON REPAIR ==="

if [ -f "src/app/favicon.ico" ]; then
    cp "src/app/favicon.ico" "public/favicon.ico"
    rm -f "src/app/favicon.ico"
    echo "PASS  favicon moved from App Router to public/"
elif [ -f "public/favicon.ico" ]; then
    echo "PASS  public/favicon.ico already exists"
else
    echo "WARN  no favicon found"
fi

# ------------------------------------------------------------
# 2. Clean previous Next artifacts
# ------------------------------------------------------------

echo
echo "=== 2. CLEAN NEXT ARTIFACTS ==="

rm -rf .next
echo "PASS  .next removed"

# ------------------------------------------------------------
# 3. Verify package build command
# ------------------------------------------------------------

echo
echo "=== 3. PACKAGE BUILD COMMAND ==="

node - <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("PASS  package build = next build --webpack");
NODE

# ------------------------------------------------------------
# 4. Repair Gate 14 deterministically
# ------------------------------------------------------------

echo
echo "=== 4. VERIFICATION GATE REPAIR ==="

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * Normalize all OMEGA temporary paths.
 */
s = s.replace(
  /(?:\.omega)+\/tmp\//g,
  ".omega/tmp/"
);

/*
 * Gate 14 must call the known-good package script.
 *
 * Do NOT use:
 *   npm exec next build -- --webpack
 *
 * and never allow duplicated argument insertion.
 */
s = s.replace(
  /npm exec next build[^\n]*/g,
  "npm run build"
);

/*
 * Repair any malformed direct Next invocation that survived.
 */
s = s.replace(
  /next build --webpack -- --webpack/g,
  "next build --webpack"
);

/*
 * If Gate 14 redirects its build output, preserve that redirection.
 */
s = s.replace(
  /npm run build\s*>\s*\.omega\/tmp\/omega-next-build\.txt[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "=== GATE 14 AUDIT ==="
grep -n -A12 -B4 "GATE 14" "$GATE" || true

echo
echo "=== NEXT INVOCATION AUDIT ==="
grep -nE 'npm exec next build|npm run build|next build' "$GATE" || true

echo
echo "=== SHELL SYNTAX ==="
bash -n "$GATE"
echo "PASS  verification gate shell syntax"

# ------------------------------------------------------------
# 5. Direct production build
# ------------------------------------------------------------

echo
echo "=== 5. DIRECT PRODUCTION BUILD ==="

if npm run build > "$TMP/omega-build-repair.txt" 2>&1; then
    tail -40 "$TMP/omega-build-repair.txt"
    echo
    echo "PASS  production build"
else
    cat "$TMP/omega-build-repair.txt"
    echo
    echo "FAIL  production build"
    exit 1
fi

# ------------------------------------------------------------
# 6. Verify artifacts
# ------------------------------------------------------------

echo
echo "=== 6. PRODUCTION ARTIFACT AUDIT ==="

test -d ".next" || {
    echo "FAIL  .next missing"
    exit 1
}

test -f "public/favicon.ico" || {
    echo "FAIL  public/favicon.ico missing"
    exit 1
}

echo "PASS  .next exists"
echo "PASS  public/favicon.ico exists"

# The problematic App Router favicon route must not exist.
if find ".next/server/app" -path "*favicon.ico/route.js" -print -quit | grep -q .; then
    echo "FAIL  favicon App Router route artifact remains"
    exit 1
else
    echo "PASS  no favicon.ico route artifact"
fi

# ------------------------------------------------------------
# 7. Test suite
# ------------------------------------------------------------

echo
echo "=== 7. TEST SUITE ==="

npm test > "$TMP/omega-build-test.txt" 2>&1
tail -20 "$TMP/omega-build-test.txt"

echo
echo "=== TEST RESULT ==="
grep -E 'ℹ pass|ℹ fail' "$TMP/omega-build-test.txt" | tail -2

echo
echo "============================================================"
echo "       OMEGA® BUILD REPAIR: PASS"
echo "============================================================"
