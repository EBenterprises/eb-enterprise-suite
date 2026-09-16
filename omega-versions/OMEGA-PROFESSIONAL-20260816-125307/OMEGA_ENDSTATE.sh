#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

CERT="$ROOT/.omega/certification"
LOG="$ROOT/.omega/tmp/endstate"
mkdir -p "$CERT" "$LOG"

TOTAL=12
STEP=0

bar() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))
    printf "\n["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s\n" "$((STEP * 100 / TOTAL))" "$1"
}

fail() {
    echo
    echo "FAIL: $1"
    echo
    exit 1
}

echo
echo "============================================================"
echo " OMEGA® — END-STATE COMPLETION"
echo "============================================================"

# 01
bar "Stop stale OMEGA build processes"
pkill -f 'next build' 2>/dev/null || true
pkill -f 'npm run build' 2>/dev/null || true
pkill -f 'OMEGA_.*CERTIFICATION' 2>/dev/null || true
echo "PASS"

# 02
bar "Validate package"
node <<'NODE' || fail "package validation"
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
const l=JSON.parse(fs.readFileSync("package-lock.json","utf8"));

if(p.name!=="omega") throw Error("name");
if(p.version!=="1.0.0") throw Error("version");
if(p.type!=="module") throw Error("type");
if(p.scripts?.build!=="next build --webpack") throw Error("build");
if(p.scripts?.dev!=="next dev --webpack") throw Error("dev");
if(l.lockfileVersion!==3) throw Error("lockfile");

console.log("PASS");
NODE

# 03
bar "Validate filesystem"

for f in \
    package.json \
    package-lock.json \
    bin/omega.js \
    src/core/omega.js \
    src/core/kernel.js \
    src/app/page.js \
    src/app/layout.js
do
    test -s "$f" || fail "missing $f"
done

for d in src tests public data; do
    test -d "$d" || fail "missing $d"
done

echo "PASS"

# 04
bar "Validate core JavaScript"

SOURCE_FAIL=0

while IFS= read -r -d '' file; do
    node --check "$file" >/dev/null 2>&1 || {
        echo "FAIL: $file"
        SOURCE_FAIL=1
    }
done < <(
    find src \
        -type f \
        \( -name "*.js" -o -name "*.mjs" \) \
        ! -path "src/app/*" \
        -print0
)

[ "$SOURCE_FAIL" -eq 0 ] || fail "core JavaScript syntax"

echo "PASS"

# 05
bar "Validate Next application"

test -s src/app/page.js || fail "page.js"
test -s src/app/layout.js || fail "layout.js"

# Do not use node --check against JSX.
echo "PASS — JSX delegated to Next.js compiler"

# 06
bar "Clean production artifacts"

rm -rf .next
echo "PASS"

# 07
bar "Build production application"

if npm run build > "$LOG/build.log" 2>&1; then
    test -d .next || fail ".next missing"
    echo "PASS"
else
    echo
    tail -100 "$LOG/build.log"
    fail "production build"
fi

# 08
bar "Run test suite"

if npm test > "$LOG/tests.log" 2>&1; then
    echo "PASS"
else
    tail -100 "$LOG/tests.log"
    fail "test suite"
fi

# 09
bar "Validate test result"

grep -Eq 'fail[[:space:]]+0|fail 0' "$LOG/tests.log" ||
    fail "non-zero test failures"

echo "PASS"

# 10
bar "Validate runtime CLI"

node bin/omega.js status >/dev/null 2>&1 ||
    fail "status"

node bin/omega.js capabilities >/dev/null 2>&1 ||
    fail "capabilities"

node bin/omega.js metrics >/dev/null 2>&1 ||
    fail "metrics"

echo "PASS"

# 11
bar "Validate data and certificate"

node <<'NODE' || exit 1
const fs=require("fs");

for(const f of [
  "data/omega-memory.json",
  "data/omega-state.json",
  "data/versions.json"
]){
  JSON.parse(fs.readFileSync(f,"utf8"));
}
NODE

DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$CERT/OMEGA_ENDSTATE_CERTIFICATE.txt" <<CERT
OMEGA® END-STATE CERTIFICATE
============================

PROJECT
OMEGA®

VERSION
1.0.0

CERTIFIED
$DATE

FILESYSTEM             PASS
PACKAGE                PASS
CORE JAVASCRIPT        PASS
NEXT APPLICATION       PASS
NEXT JSX COMPILER      PASS
PRODUCTION BUILD       PASS
TEST SUITE             PASS
RUNTIME CLI            PASS
DATA INTEGRITY         PASS

STATUS
CERTIFIED
CERT

echo "PASS"

# 12
bar "Final status"

echo
echo "============================================================"
echo " [########################################] 100%"
echo "============================================================"
echo
echo "OMEGA® END STATE"
echo
echo "BUILD        : PASS"
echo "TESTS        : PASS"
echo "CLI          : PASS"
echo "NEXT         : PASS"
echo "JSX          : PASS"
echo "DATA         : PASS"
echo "CERTIFICATE  : PASS"
echo
echo "STATUS       : OMEGA® CERTIFIED"
echo
echo "Certificate:"
echo "$CERT/OMEGA_ENDSTATE_CERTIFICATE.txt"
echo
echo "============================================================"
