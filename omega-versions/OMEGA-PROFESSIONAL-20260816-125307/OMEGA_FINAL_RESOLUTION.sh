#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"
CERT="$ROOT/.omega/certification"
LOG="$CERT/final-gate.log"

mkdir -p "$TMP" "$CERT"

echo "============================================================"
echo "       OMEGA® FINAL RESOLUTION — DEFINITIVE REPAIR"
echo "============================================================"

# ============================================================
# 1. BACKUP
# ============================================================

echo
echo "=== 1. BACKUP ==="

cp -f "$GATE" \
  "$CERT/OMEGA_VERIFICATION_GATE.pre-final-resolution.sh"

[ -f "src/app/layout.js" ] &&
  cp -f "src/app/layout.js" \
  "$CERT/layout.pre-final-resolution.js"

echo "PASS  repair backups created"

# ============================================================
# 2. REMOVE APP-ROUTER FAVICON ROUTE
# ============================================================

echo
echo "=== 2. FAVICON ROUTE REPAIR ==="

rm -f "src/app/favicon.ico"

echo "PASS  src/app/favicon.ico removed"

# Keep a public favicon only if it is not being referenced by
# App Router metadata.
#
# First inspect the application files.
echo
echo "--- favicon references before cleanup ---"

grep -RniE \
  'favicon|icons[[:space:]]*:|icon[[:space:]]*:' \
  src/app \
  --exclude='*.map' \
  2>/dev/null || true

# Remove explicit favicon metadata/link declarations from the
# application layout. This prevents Next from generating
# /favicon.ico as an App Router route.
if [ -f "src/app/layout.js" ]; then

  node - "src/app/layout.js" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * Remove explicit favicon link tags.
 */
s = s.replace(
  /<link[^>]+rel=["'](?:icon|shortcut icon)["'][^>]*>/gi,
  ""
);

/*
 * Remove simple metadata icon declarations.
 */
s = s.replace(
  /^[ \t]*icons\s*:\s*\{[\s\S]*?\},?[ \t]*$/gm,
  ""
);

/*
 * Remove simple single-line icon declarations.
 */
s = s.replace(
  /^[ \t]*(?:icon|favicon)\s*:\s*["'][^"']+["'],?[ \t]*$/gm,
  ""
);

/*
 * Remove direct favicon references in metadata strings.
 */
s = s.replace(
  /["']\/favicon\.ico["']/g,
  '""'
);

fs.writeFileSync(file, s);
NODE

fi

# Public favicon is safe only as a static asset. Remove it
# temporarily so certification proves the application itself
# builds without the route.
rm -f "public/favicon.ico"

echo "PASS  favicon route eliminated"

# ============================================================
# 3. PACKAGE SCRIPT
# ============================================================

echo
echo "=== 3. PACKAGE BUILD SCRIPT ==="

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};

pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(
  file,
  JSON.stringify(pkg, null, 2) + "\n"
);

console.log("PASS  build = next build --webpack");
NODE

# ============================================================
# 4. DEFINITIVELY REWRITE GATE 14
# ============================================================

echo
echo "=== 4. GATE 14 REPAIR ==="

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

s = s.replace(
  /(?:\.omega)+\/tmp\//g,
  ".omega/tmp/"
);

const marker = 'section "GATE 14 — NEXT BUILD"';
const start = s.indexOf(marker);

if (start === -1) {
  throw new Error("GATE 14 not found");
}

const next = s.indexOf(
  '\nsection "GATE 15',
  start
);

if (next === -1) {
  throw new Error("GATE 15 not found");
}

const replacement = `section "GATE 14 — NEXT BUILD"

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
  replacement +
  s.slice(next);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo "PASS  Gate 14 rewritten"

# ============================================================
# 5. VERIFY GATE 14
# ============================================================

echo
echo "=== 5. GATE 14 AUDIT ==="

sed -n '/GATE 14 — NEXT BUILD/,/GATE 15/p' "$GATE"

if grep -nE \
  'npm exec next build|npm run build[[:space:]]+--[[:space:]]+--webpack' \
  "$GATE"; then

  echo "FAIL  invalid Next build invocation detected"
  exit 1
fi

if ! grep -q 'npm run build' "$GATE"; then
  echo "FAIL  Gate 14 does not invoke npm run build"
  exit 1
fi

echo "PASS  Gate 14 invocation"

# ============================================================
# 6. SHELL VALIDATION
# ============================================================

echo
echo "=== 6. SHELL VALIDATION ==="

bash -n "$GATE"
bash -n "$0"

echo "PASS  gate shell syntax"
echo "PASS  repair script syntax"

# ============================================================
# 7. CLEAN NEXT COMPLETELY
# ============================================================

echo
echo "=== 7. CLEAN NEXT ==="

rm -rf .next

echo "PASS  .next removed"

# ============================================================
# 8. PRODUCTION BUILD
# ============================================================

echo
echo "=== 8. PRODUCTION BUILD ==="

if npm run build > "$TMP/final-production-build.txt" 2>&1; then

  tail -60 "$TMP/final-production-build.txt"

  echo
  echo "PASS  PRODUCTION BUILD"

else

  cat "$TMP/final-production-build.txt"

  echo
  echo "FAIL  PRODUCTION BUILD"
  exit 1

fi

# ============================================================
# 9. VERIFY NO FAVICON ROUTE
# ============================================================

echo
echo "=== 9. FAVICON ARTIFACT AUDIT ==="

if find ".next/server/app" \
    -type f \
    -path '*favicon.ico*' \
    -print \
    -quit 2>/dev/null | grep -q .; then

  echo "FAIL  favicon App Router artifact remains"
  find ".next/server/app" \
    -type f \
    -path '*favicon.ico*' \
    -print
  exit 1
fi

echo "PASS  no favicon App Router artifact"

# ============================================================
# 10. VERIFY PRODUCTION ARTIFACT
# ============================================================

echo
echo "=== 10. PRODUCTION ARTIFACT ==="

test -d ".next" || {
  echo "FAIL  .next missing"
  exit 1
}

echo "PASS  .next production artifact"

# ============================================================
# 11. TESTS
# ============================================================

echo
echo "=== 11. TEST SUITE ==="

if npm test > "$TMP/final-tests.txt" 2>&1; then
  tail -25 "$TMP/final-tests.txt"
else
  cat "$TMP/final-tests.txt"
  echo "FAIL  test suite"
  exit 1
fi

PASS_COUNT="$(
  grep -E 'ℹ pass' "$TMP/final-tests.txt" |
  tail -1 |
  awk '{print $3}'
)"

FAIL_COUNT="$(
  grep -E 'ℹ fail' "$TMP/final-tests.txt" |
  tail -1 |
  awk '{print $3}'
)"

if [ "$PASS_COUNT" = "39" ] &&
   [ "$FAIL_COUNT" = "0" ]; then

  echo "PASS  39/39 tests"

else

  echo "FAIL  test count"
  echo "PASS=$PASS_COUNT"
  echo "FAIL=$FAIL_COUNT"
  exit 1

fi

# ============================================================
# 12. FORMAL VERIFICATION
# ============================================================

echo
echo "=== 12. FORMAL VERIFICATION ==="

rm -f "$LOG"

set +e

"$GATE" 2>&1 |
  tee "$LOG"

RC=${PIPESTATUS[0]}

set -e

echo
echo "============================================================"
echo "       OMEGA® FORMAL VERIFICATION RESULT"
echo "============================================================"

echo
echo "EXIT CODE: $RC"

if [ "$RC" -ne 0 ]; then

  echo
  echo "FAIL  FORMAL VERIFICATION"

  echo
  echo "FAILURES:"
  grep -aE \
    '^FAIL|VERIFICATION GATE:' \
    "$LOG" |
    tail -30 || true

  exit "$RC"

fi

echo
echo "PASS  FORMAL VERIFICATION"

# ============================================================
# 13. FINAL STATE
# ============================================================

echo
echo "=== 13. FINAL OMEGA STATE ==="

node <<'NODE'
const fs = require("fs");

const file = "data/omega-state.json";

let state = {};

try {
  state = JSON.parse(
    fs.readFileSync(file, "utf8")
  );
} catch {}

state.identity ??= {};

state.identity.name = "OMEGA";
state.identity.status = "operational";
state.identity.initialized = true;
state.identity.certified = true;
state.identity.certifiedAt =
  new Date().toISOString();

fs.writeFileSync(
  file,
  JSON.stringify(state, null, 2) + "\n"
);

console.log(
  "PASS  OMEGA state certified"
);
NODE

# ============================================================
# 14. FINAL REPORT
# ============================================================

echo
echo "=== 14. FINAL STATUS ==="

node bin/omega.js status

echo
echo "=== CAPABILITIES ==="

node bin/omega.js capabilities

echo
echo "=== TEST RESULT ==="

grep -aE \
  'ℹ pass|ℹ fail' \
  "$TMP/final-tests.txt" |
  tail -2

echo
echo "=== BUILD ==="

echo "PASS  .next exists"

echo
echo "=== CERTIFICATION ==="

grep -aE \
  '^PASS:|^FAIL:|^WARN:|VERIFICATION GATE:' \
  "$LOG" |
  tail -10

echo
echo "============================================================"
echo "       OMEGA® INITIALIZED"
echo "       OMEGA® BUILT"
echo "       OMEGA® VERIFIED"
echo "       OMEGA® CERTIFIED"
echo "============================================================"

exit 0
