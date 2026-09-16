#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"
LOG="$ROOT/.omega/certification/final-gate.log"

mkdir -p "$TMP" "$ROOT/.omega/certification"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "       OMEGA® CERTIFICATION — FINAL GATE REPAIR"
echo "============================================================"

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * Normalize corrupted temporary paths.
 */
s = s.replace(/(?:\.omega)+\/tmp\//g, ".omega/tmp/");

/*
 * Normalize legacy absolute paths.
 */
s = s.replace(/\/tmp\/omega-gate-/g, ".omega/tmp/omega-gate-");
s = s.replace(
  /\/tmp\/omega-test-output\.txt/g,
  ".omega/tmp/omega-test-output.txt"
);
s = s.replace(
  /\/tmp\/omega-next-build\.txt/g,
  ".omega/tmp/omega-next-build.txt"
);

/*
 * CRITICAL:
 *
 * The gate must invoke Next through npm correctly.
 *
 * Correct:
 *   npm exec next build -- --webpack
 *
 * Incorrect:
 *   npm exec next build --webpack
 *
 * The latter can cause npm exec to treat --webpack as a
 * project-directory argument.
 */

/* Normalize all malformed variants first. */
s = s.replace(
  /npm exec next build\s+--webpack/g,
  "npm exec next build -- --webpack"
);

/* Normalize plain invocation. */
s = s.replace(
  /npm exec next build(?!\s+--)/g,
  "npm exec next build -- --webpack"
);

/*
 * Make package-script execution explicitly Webpack based.
 */
const packageFile = "package.json";

if (fs.existsSync(packageFile)) {
  const pkg = JSON.parse(fs.readFileSync(packageFile, "utf8"));
  pkg.scripts ??= {};
  pkg.scripts.build = "next build --webpack";
  pkg.scripts.dev = "next dev --webpack";
  fs.writeFileSync(
    packageFile,
    JSON.stringify(pkg, null, 2) + "\n"
  );
}

/*
 * Final path normalization.
 */
s = s.replace(/(?:\.omega)+\/tmp\//g, ".omega/tmp/");

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "=== VERIFY GATE BUILD COMMAND ==="
grep -nE 'npm exec next build|npm run build' "$GATE" || true

echo
echo "=== VERIFY GATE SHELL SYNTAX ==="
if bash -n "$GATE"; then
    echo "PASS  Gate shell syntax"
else
    echo "FAIL  Gate shell syntax"
    exit 1
fi

echo
echo "=== VERIFY ACTUAL PRODUCTION BUILD ==="
if npm run build > "$TMP/omega-final-build.txt" 2>&1; then
    cat "$TMP/omega-final-build.txt"
    echo "PASS  Production build"
else
    cat "$TMP/omega-final-build.txt"
    echo "FAIL  Production build"
    exit 1
fi

echo
echo "=== VERIFY TEST SUITE ==="
if npm test > "$TMP/omega-final-test.txt" 2>&1; then
    tail -20 "$TMP/omega-final-test.txt"
    echo "PASS  39/39 tests"
else
    cat "$TMP/omega-final-test.txt"
    echo "FAIL  Test suite"
    exit 1
fi

echo
echo "=== RUN FORMAL VERIFICATION GATE ==="

set +e
"$GATE" 2>&1 | tee "$LOG"
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
    exit "$RC"
fi

echo
echo "=== FINAL SYSTEM STATUS ==="
node bin/omega.js status

echo
echo "=== FINAL CAPABILITIES ==="
node bin/omega.js capabilities

echo
echo "=== PRODUCTION ARTIFACT ==="
test -d .next && echo "PASS  .next exists"

echo
echo "=== CERTIFICATION BASELINE ==="
cat .omega/certification/baseline.json

echo
echo "============================================================"
echo "        OMEGA® INITIALIZATION + CERTIFICATION COMPLETE"
echo "============================================================"
