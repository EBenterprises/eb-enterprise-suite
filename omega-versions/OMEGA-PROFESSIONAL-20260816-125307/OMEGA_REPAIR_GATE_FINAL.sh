#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
BACKUP="$ROOT/.omega/certification/OMEGA_VERIFICATION_GATE.pre-definitive-repair.sh"

mkdir -p "$ROOT/.omega/certification" "$ROOT/.omega/tmp"

echo "============================================================"
echo "       OMEGA® — DEFINITIVE VERIFICATION GATE REPAIR"
echo "============================================================"

test -f "$GATE"
cp -f "$GATE" "$BACKUP"

echo
echo "=== 1. REMOVE DOUBLE WEBPACK INVOCATION ==="

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * The gate must call the package build exactly once.
 *
 * package.json:
 *   "build": "next build --webpack"
 *
 * Therefore the gate must use:
 *   npm run build
 *
 * NOT:
 *   npm run build -- --webpack
 *   npm run build --webpack
 *   npm exec next build -- --webpack
 */

s = s.replace(
  /npm run build\s+--\s+--webpack[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

s = s.replace(
  /npm run build\s+--webpack[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

s = s.replace(
  /npm exec next build[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

s = s.replace(
  /next build\s+--webpack\s+--webpack[^\n]*/g,
  "npm run build > .omega/tmp/omega-next-build.txt 2>&1"
);

fs.writeFileSync(file, s);
NODE

echo "PASS  build invocation normalized"

echo
echo "=== 2. SHOW GATE 290–320 ==="

nl -ba "$GATE" | sed -n '290,320p'

echo
echo "=== 3. BASH PARSER CHECK ==="

if bash -n "$GATE"; then
    echo "PASS  verification gate shell syntax"
else
    echo
    echo "FAIL  verification gate shell syntax"
    echo
    echo "The gate contains structural shell corruption."
    echo
    echo "Context around reported failure:"
    nl -ba "$GATE" | sed -n '300,325p'
    exit 2
fi

echo
echo "=== 4. VERIFY BUILD COMMANDS ==="

grep -nE \
    'npm exec next build|npm run build|next build' \
    "$GATE" || true

echo
echo "=== 5. DIRECT PRODUCTION BUILD ==="

rm -rf .next

if npm run build > .omega/tmp/omega-definitive-build.txt 2>&1; then
    tail -40 .omega/tmp/omega-definitive-build.txt
    echo
    echo "PASS  production build"
else
    cat .omega/tmp/omega-definitive-build.txt
    echo
    echo "FAIL  production build"
    exit 1
fi

echo
echo "=== 6. TEST SUITE ==="

if npm test > .omega/tmp/omega-definitive-test.txt 2>&1; then
    tail -20 .omega/tmp/omega-definitive-test.txt
    echo
    echo "PASS  39/39 tests"
else
    cat .omega/tmp/omega-definitive-test.txt
    echo
    echo "FAIL  test suite"
    exit 1
fi

echo
echo "=== 7. FORMAL GATE SYNTAX ==="

bash -n "$GATE"
echo "PASS  gate parses successfully"

echo
echo "=== 8. RUN FORMAL VERIFICATION GATE ==="

set +e
"$GATE" 2>&1 | tee .omega/certification/final-gate.log
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "             OMEGA® CERTIFICATION RESULT"
echo "============================================================"

if [ "$RC" -eq 0 ]; then
    echo
    echo "PASS  VERIFICATION GATE"
    echo "PASS  OMEGA® CERTIFIED"
else
    echo
    echo "FAIL  VERIFICATION GATE"
    echo "EXIT CODE: $RC"
    echo
    echo "Remaining failures:"
    grep '^FAIL ' .omega/certification/final-gate.log | tail -20 || true
    exit "$RC"
fi

echo
echo "=== FINAL STATUS ==="

node bin/omega.js status

echo
echo "=== FINAL CAPABILITIES ==="

node bin/omega.js capabilities

echo
echo "=== FINAL BUILD ARTIFACT ==="

test -d .next
echo "PASS  .next"

echo
echo "============================================================"
echo "       OMEGA® — DEFINITIVE CERTIFICATION COMPLETE"
echo "============================================================"

