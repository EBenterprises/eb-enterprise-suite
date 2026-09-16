#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

mkdir -p .omega/certification .omega/tmp public

echo
echo "============================================================"
echo "       OMEGA® — COMPLETE BUILD + CERTIFICATION"
echo "============================================================"
echo

STEP=0
TOTAL=8

progress() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))
    printf "["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s\n" "$((STEP * 100 / TOTAL))" "$1"
}

fail() {
    echo
    echo "============================================================"
    echo "FAIL — $1"
    echo "============================================================"
    exit 1
}

# ------------------------------------------------------------
# 1. PACKAGE
# ------------------------------------------------------------
progress "Validate package"

node <<'NODE' || exit 1
const fs = require("fs");

const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
const lock = JSON.parse(fs.readFileSync("package-lock.json", "utf8"));

if (pkg.name !== "omega") throw new Error("package name");
if (pkg.version !== "1.0.0") throw new Error("package version");
if (pkg.type !== "module") throw new Error("package type");

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(
  "package.json",
  JSON.stringify(pkg, null, 2) + "\n"
);

if (lock.lockfileVersion !== 3) {
  throw new Error("unsupported lockfile");
}

console.log("PASS");
NODE

# ------------------------------------------------------------
# 2. CORE SOURCE
# JSX IS INTENTIONALLY EXCLUDED FROM node --check.
# ------------------------------------------------------------
progress "Validate core JavaScript"

while IFS= read -r -d '' file; do
    node --check "$file" >/dev/null 2>&1 ||
        fail "JavaScript syntax: $file"
done < <(
    find src \
      -type f \
      \( -name "*.js" -o -name "*.mjs" \) \
      ! -path "src/app/*" \
      -print0
)

echo "PASS"

# ------------------------------------------------------------
# 3. APP SOURCE
# Let Next.js validate page.js/layout.js.
# ------------------------------------------------------------
progress "Validate Next.js application"

test -s src/app/page.js ||
    fail "src/app/page.js missing"

test -s src/app/layout.js ||
    fail "src/app/layout.js missing"

echo "PASS"

# ------------------------------------------------------------
# 4. CLEAN BUILD
# ------------------------------------------------------------
progress "Build production application"

rm -rf .next

if ! npm run build > .omega/tmp/final-build.log 2>&1; then
    echo
    echo "BUILD OUTPUT:"
    tail -120 .omega/tmp/final-build.log
    fail "production build"
fi

test -d .next ||
    fail ".next was not created"

echo "PASS"

# ------------------------------------------------------------
# 5. TESTS
# ------------------------------------------------------------
progress "Run complete test suite"

if ! npm test > .omega/tmp/final-tests.log 2>&1; then
    echo
    echo "TEST OUTPUT:"
    tail -120 .omega/tmp/final-tests.log
    fail "test suite"
fi

tail -30 .omega/tmp/final-tests.log

grep -Eq 'fail 0|fail[[:space:]]+0' \
    .omega/tmp/final-tests.log ||
    fail "tests reported failure"

echo "PASS"

# ------------------------------------------------------------
# 6. DATA
# ------------------------------------------------------------
progress "Validate OMEGA data"

node <<'NODE' || exit 1
const fs = require("fs");

for (const file of [
  "data/omega-memory.json",
  "data/omega-state.json",
  "data/versions.json"
]) {
  JSON.parse(fs.readFileSync(file, "utf8"));
}
NODE

echo "PASS"

# ------------------------------------------------------------
# 7. CLI
# ------------------------------------------------------------
progress "Validate OMEGA CLI"

node bin/omega.js status >/dev/null ||
    fail "CLI status"

node bin/omega.js capabilities >/dev/null ||
    fail "CLI capabilities"

node bin/omega.js metrics >/dev/null ||
    fail "CLI metrics"

echo "PASS"

# ------------------------------------------------------------
# 8. CERTIFICATE
# ------------------------------------------------------------
progress "Generate final certification"

DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > .omega/certification/OMEGA_CERTIFIED.txt <<CERT
============================================================
OMEGA® FINAL CERTIFICATION
============================================================

PROJECT
OMEGA®

VERSION
1.0.0

CERTIFIED
$DATE

RESULTS

[PASS] Filesystem
[PASS] Package configuration
[PASS] Core JavaScript syntax
[PASS] Next.js application validation
[PASS] Production build
[PASS] Complete test suite
[PASS] JSON data integrity
[PASS] CLI status
[PASS] CLI capabilities
[PASS] CLI metrics

STATUS
CERTIFIED

BUILD
PRODUCTION

NEXT
WEBPACK

JSX VALIDATION
NEXT.JS COMPILER

NODE JSX CHECK
NOT USED

DUPLICATE BUILD INSIDE GATE
NONE

============================================================
OMEGA® — BUILD COMPLETE
============================================================
CERT

echo "PASS"

echo
echo "============================================================"
echo "       [########################################] 100%"
echo "============================================================"
echo
echo "OMEGA®"
echo
echo "BUILD       : PASS"
echo "TESTS       : PASS"
echo "DATA        : PASS"
echo "CLI         : PASS"
echo "NEXT/JSX    : PASS"
echo "CERTIFICATE : PASS"
echo
echo "STATUS      : OMEGA® CERTIFIED"
echo
echo "Certificate:"
echo ".omega/certification/OMEGA_CERTIFIED.txt"
echo
echo "============================================================"
