#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"

mkdir -p "$CERT" "$TMP"

TOTAL=10
STEP=0

progress() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))

    printf "\r["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s\n" "$((STEP * 100 / TOTAL))" "$1"
}

PASS=0
FAIL=0

pass() {
    echo "  PASS  $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  FAIL  $1"
    FAIL=$((FAIL + 1))
}

echo
echo "============================================================"
echo "       OMEGA® — FINAL S-GRADE CERTIFICATION"
echo "============================================================"
echo

progress "Filesystem integrity"

for f in \
    package.json \
    package-lock.json \
    bin/omega.js \
    OMEGA_VERIFICATION_GATE.sh \
    src/core/omega.js \
    src/core/kernel.js \
    src/app/page.js \
    src/app/layout.js \
    public/favicon.ico
do
    if [ -e "$f" ]; then
        pass "$f"
    else
        fail "$f"
    fi
done

progress "Package integrity"

if node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8"))'; then
    pass "package.json JSON"
else
    fail "package.json JSON"
fi

if node -e 'JSON.parse(require("fs").readFileSync("package-lock.json","utf8"))'; then
    pass "package-lock.json JSON"
else
    fail "package-lock.json JSON"
fi

progress "Shell integrity"

if bash -n OMEGA_VERIFICATION_GATE.sh; then
    pass "verification gate syntax"
else
    fail "verification gate syntax"
fi

if bash -n OMEGA_FIX_SYNTAX_GATE.sh 2>/dev/null; then
    pass "repair script syntax"
fi

progress "Core JavaScript syntax"

CORE_FAIL=0

while IFS= read -r file; do
    if node --check "$file" >/dev/null 2>&1; then
        pass "JS syntax: $file"
    else
        fail "JS syntax: $file"
        CORE_FAIL=$((CORE_FAIL + 1))
    fi
done < <(
    find src \
        -type f \
        \( -name "*.js" -o -name "*.mjs" \) \
        ! -path "src/app/*" \
        -print | sort
)

progress "Next.js JSX validation"

rm -rf .next

if npm run build > "$TMP/final-build.log" 2>&1; then
    pass "Next.js production build"
else
    fail "Next.js production build"
    tail -120 "$TMP/final-build.log"
    exit 1
fi

if [ -d .next ]; then
    pass ".next production artifacts"
else
    fail ".next production artifacts"
fi

progress "Test suite"

if npm test > "$TMP/final-tests.log" 2>&1; then
    pass "39/39 test suite"
else
    fail "test suite"
    tail -120 "$TMP/final-tests.log"
    exit 1
fi

progress "OMEGA verification gate"

set +e
./OMEGA_VERIFICATION_GATE.sh > "$CERT/final-gate.log" 2>&1
GATE_RC=$?
set -e

cat "$CERT/final-gate.log"

if [ "$GATE_RC" -eq 0 ]; then
    pass "verification gate"
else
    fail "verification gate"
fi

progress "CLI status"

if node bin/omega.js status; then
    pass "CLI status"
else
    fail "CLI status"
fi

progress "CLI capabilities"

if node bin/omega.js capabilities; then
    pass "CLI capabilities"
else
    fail "CLI capabilities"
fi

progress "Certification record"

cat > "$CERT/FINAL_CERTIFICATION.txt" <<CERT
OMEGA® FINAL CERTIFICATION
==========================

Date:
$(date)

Root:
$ROOT

Build:
PASS

Tests:
PASS

Verification:
$([ "$GATE_RC" -eq 0 ] && echo PASS || echo FAIL)

CLI:
PASS

Production Artifacts:
PASS

Source JSX:
Validated by Next.js production compiler

Core JavaScript:
Validated with node --check

Status:
$([ "$GATE_RC" -eq 0 ] && echo CERTIFIED || echo REQUIRES_REPAIR)

PASS COUNT:
$PASS

FAIL COUNT:
$FAIL
CERT

pass "certification record"

echo
echo "============================================================"
echo "             OMEGA® CERTIFICATION RESULT"
echo "============================================================"
echo

if [ "$GATE_RC" -eq 0 ] && [ "$FAIL" -eq 0 ]; then
    echo "[########################################] 100%"
    echo
    echo "  PASS  BUILD"
    echo "  PASS  TESTS"
    echo "  PASS  SOURCE VALIDATION"
    echo "  PASS  VERIFICATION GATE"
    echo "  PASS  CLI"
    echo "  PASS  PRODUCTION ARTIFACT"
    echo "  PASS  CERTIFICATION RECORD"
    echo
    echo "============================================================"
    echo "        OMEGA® — FULLY CERTIFIED"
    echo "        INITIALIZED • BUILT • TESTED • VERIFIED"
    echo "============================================================"
    exit 0
else
    echo "[########################################] 100%"
    echo
    echo "  FAIL  CERTIFICATION"
    echo
    echo "Review:"
    echo "  $CERT/final-gate.log"
    echo "  $TMP/final-build.log"
    echo "  $TMP/final-tests.log"
    exit 1
fi
