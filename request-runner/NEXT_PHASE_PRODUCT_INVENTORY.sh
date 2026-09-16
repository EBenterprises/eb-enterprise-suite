#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

bad() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo "=============================================================="
echo " REQUEST RUNNER® — NEXT PHASE PRODUCT INVENTORY"
echo " READ-ONLY / NO MUTATION"
echo "=============================================================="

echo
echo "[1] GREEN BASELINE"
echo "--------------------------------------------------------------"

./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1 &&
    ok "Production baseline remains GREEN" ||
    bad "Production baseline changed"

echo
echo "[2] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

for f in \
    apps/request-runner/index.js \
    framework/index.js \
    package.json \
    server.js \
    config/platform.json
do
    [ -f "$f" ] &&
        ok "$f" ||
        bad "$f missing"
done

echo
echo "[3] REQUEST RUNNER® MODULES"
echo "--------------------------------------------------------------"

if [ -d apps/request-runner ]; then
    find apps/request-runner -maxdepth 2 -type f \
        ! -path '*/node_modules/*' |
        sort |
        head -n 80
    ok "Application surface inventoried"
else
    bad "Application directory missing"
fi

echo
echo "[4] FRAMEWORK SURFACE"
echo "--------------------------------------------------------------"

if [ -d framework ]; then
    find framework -maxdepth 3 -type f \
        ! -path '*/node_modules/*' |
        sort |
        head -n 120
    ok "Framework surface inventoried"
else
    bad "Framework directory missing"
fi

echo
echo "[5] AVAILABLE COMMANDS"
echo "--------------------------------------------------------------"

node - <<'NODE'
const p = require("./package.json");
console.log(JSON.stringify(p.scripts || {}, null, 2));
NODE

ok "Package command surface inspected"

echo
echo "[6] GIT STATE"
echo "--------------------------------------------------------------"

if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    git status --short
    ok "Git state inspected"
else
    echo "Git repository not detected"
fi

echo
echo "=============================================================="
echo " INVENTORY RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "NEXT PHASE READY"
    echo "NO APPLICATION FILES MODIFIED"
else
    echo "STATUS: RED"
    echo "STOP — BASELINE PROTECTION FAILED"
    exit 1
fi

echo "=============================================================="
