#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/.finalize-$STAMP"
mkdir -p "$OUT"

echo "=== REQUEST RUNNER® — FINALIZE / RELEASE READINESS ==="

echo "[1] CLEAN VERIFICATION"
./MASS_COMPLETE_REQUEST_RUNNER.sh >"$OUT/verification.log" 2>&1 || {
    tail -40 "$OUT/verification.log"
    echo "✗ Verification failed"
    exit 1
}
echo "✓ Verification passed"

echo "[2] AUTHORIZATION"
node <<'NODE' || exit 1
const Authorization = require("./framework/security/authorization");
if (typeof Authorization !== "function") process.exit(1);
const auth = new Authorization();
auth.grant("operations", "request.manage");
if (!auth.allows("operations", "request.manage")) process.exit(1);
console.log("✓ Authorization contract"
);
NODE

echo "[3] PACKAGE"
node <<'NODE' || exit 1
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json","utf8"));

if (!p.name) process.exit(1);
if (!p.version) process.exit(1);
if (!p.scripts?.build) process.exit(1);
if (!p.scripts?.start) process.exit(1);

console.log("✓", p.name, p.version);
console.log("✓ build script");
console.log("✓ start script");
NODE

echo "[4] SOURCE INVENTORY"
find app framework apps bin tests \
    -type f \
    -not -path '*/node_modules/*' \
    2>/dev/null \
    | sort >"$OUT/source-files.txt"

wc -l <"$OUT/source-files.txt" | awk '{print "✓ Source files:",$1}'

echo "[5] SECURITY CONTRACT"
test -f framework/security/authorization.js || {
    echo "✗ Authorization implementation missing"
    exit 1
}
grep -q '^class Authorization' framework/security/authorization.js || {
    echo "✗ Authorization class missing"
    exit 1
}
grep -q '^module\.exports = Authorization;' framework/security/authorization.js || {
    echo "✗ Authorization constructor export missing"
    exit 1
}
echo "✓ Authorization export locked"

echo "[6] BUILD ARTIFACT"
test -d .next || {
    echo "✗ .next missing"
    exit 1
}
echo "✓ .next exists"

echo "[7] GIT"
if command -v git >/dev/null 2>&1; then
    echo "✓ Git available"
    git --version
else
    echo "! Git not installed"
    echo "Install with:"
    echo "pkg install git -y"
fi

echo "[8] BACKUP"
tar \
    --exclude=node_modules \
    --exclude=.next \
    --exclude=.git \
    --exclude='.mass-complete-*' \
    --exclude='.finalize-*' \
    -czf "$OUT/request-runner-source-$STAMP.tar.gz" \
    app framework apps bin tests package.json next.config.js server.js \
    2>/dev/null || {
        echo "✗ Source archive failed"
        exit 1
    }

echo "✓ Source archive created"

echo "[9] RELEASE MANIFEST"
cat >"$OUT/RELEASE_MANIFEST.txt" <<MANIFEST
REQUEST RUNNER®
EB Platform®

Release timestamp: $STAMP
Verification: PASSED
Production build: PASSED
Doctor: PASSED
Tests: PASSED
Status: PASSED
Health: PASSED
API surface: PASSED
Frontend surface: PASSED
Authorization: PASSED
Server fatal/unhandled scan: PASSED

Persistence: JSON

Required API modules:
customers
requests
orders
drivers
locations
scheduling
payments
notifications
operations
administration

Frontend:
/
/request
/requests
/orders
/drivers
/ops

Source archive:
request-runner-source-$STAMP.tar.gz
MANIFEST

echo "✓ Release manifest"

echo
echo "=== REQUEST RUNNER® — RELEASE READY ==="
echo "Status: GREEN"
echo "Artifacts: $OUT"
echo "Archive: $OUT/request-runner-source-$STAMP.tar.gz"
echo "Manifest: $OUT/RELEASE_MANIFEST.txt"
