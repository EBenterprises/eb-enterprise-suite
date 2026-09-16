#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"

echo "============================================================"
echo "       OMEGA® FINAL GATE AUDIT CORRECTION"
echo "============================================================"

echo
echo "=== 1. VERIFY TEMP PATHS ==="

if grep -nF '.omega.omega' "$GATE"; then
    echo "FAIL: repeated .omega path remains"
    exit 1
fi

if grep -nF '/tmp/omega-' "$GATE"; then
    echo "FAIL: legacy absolute temporary path remains"
    exit 1
fi

echo "PASS: temporary paths are normalized"

echo
echo "=== 2. VERIFY WORKSPACE ==="

mkdir -p "$ROOT/.omega/tmp"
chmod 700 "$ROOT/.omega" "$ROOT/.omega/tmp"

if [ -d "$ROOT/.omega/tmp" ]; then
    echo "PASS: .omega/tmp exists"
else
    echo "FAIL: .omega/tmp missing"
    exit 1
fi

echo
echo "=== 3. VERIFY NEXT BUILD ==="

if grep -nF 'next build -- --webpack' "$GATE"; then
    echo "PASS: Webpack build enforced"
else
    echo "FAIL: Webpack build not enforced"
    exit 1
fi

echo
echo "=== 4. VERIFY GATE SHELL SYNTAX ==="

if bash -n "$GATE"; then
    echo "PASS: verification gate shell syntax"
else
    echo "FAIL: verification gate shell syntax"
    exit 1
fi

echo
echo "=== 5. VERIFY PACKAGE BUILD ==="

if grep -nF '"build": "next build --webpack"' package.json; then
    echo "PASS: package build uses Webpack"
else
    echo "FAIL: package build configuration"
    exit 1
fi

echo
echo "=== 6. VERIFY TEST SCRIPT ==="

if npm test >/dev/null 2>&1; then
    echo "PASS: npm test"
else
    echo "FAIL: npm test"
    npm test
    exit 1
fi

echo
echo "=== 7. VERIFY PRODUCTION BUILD ==="

if npm run build >/dev/null 2>&1; then
    echo "PASS: production build"
else
    echo "FAIL: production build"
    npm run build
    exit 1
fi

echo
echo "============================================================"
echo "        FINAL GATE AUDIT: PASS"
echo "============================================================"
