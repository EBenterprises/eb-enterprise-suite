#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
mkdir -p "$CERT" "$TMP"

fail() {
    echo
    echo "FAIL — $1"
    exit 1
}

pass() {
    echo "PASS  $1"
}

echo
echo "============================================================"
echo "          OMEGA® — POST RELEASE VERIFICATION"
echo "============================================================"

echo
echo "=== 1. PYTHON ==="
if command -v python >/dev/null 2>&1; then
    python --version
    pass "Python installed"
else
    echo "Installing Python..."
    pkg update -y
    pkg install -y python
    command -v python >/dev/null 2>&1 \
        || fail "Python installation failed"
    python --version
    pass "Python installed"
fi

echo
echo "=== 2. RELEASE LOCK ==="
test -x OMEGA_FINAL_RELEASE_LOCK.sh \
    || fail "release lock missing"

bash -n OMEGA_FINAL_RELEASE_LOCK.sh \
    || fail "release lock syntax"

pass "release lock valid"

echo
echo "=== 3. MANIFEST ==="
MANIFEST="$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt"

test -s "$MANIFEST" \
    || fail "release manifest missing"

grep -q '^OMEGA® FINAL RELEASE MANIFEST$' "$MANIFEST" \
    || fail "manifest identity missing"

grep -q '^FINAL STATUS:$' "$MANIFEST" \
    || fail "manifest final status missing"

grep -q 'OMEGA® PRODUCTION CERTIFIED + HARDENED' "$MANIFEST" \
    || fail "manifest certification status missing"

pass "release manifest valid"

echo
echo "=== 4. RELEASE HASH ==="
RELEASE_HASH="$CERT/OMEGA_FINAL_RELEASE_SHA256.txt"

test -s "$RELEASE_HASH" \
    || fail "release SHA256 missing"

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$MANIFEST" \
    > "$TMP/release-sha256-recomputed.txt"

cmp -s \
    "$RELEASE_HASH" \
    "$TMP/release-sha256-recomputed.txt" \
    || fail "release SHA256 mismatch"

pass "release SHA256 verified"

echo
echo "=== 5. GIT IDENTITY ==="
LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/master)"

[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] \
    || fail "GitHub HEAD mismatch"

pass "GitHub synchronized"

echo
echo "=== 6. BUILD ARTIFACTS ==="
test -s .next/BUILD_ID \
    || fail "Next.js BUILD_ID missing"

BUILD_ID="$(cat .next/BUILD_ID)"

test -d .next/server \
    || fail "Next.js server artifact directory missing"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

[ "$SERVER_FILES" -gt 0 ] \
    || fail "server artifact tree empty"

echo "BUILD ID: $BUILD_ID"
echo "SERVER ARTIFACTS: $SERVER_FILES"

pass "production artifacts verified"

echo
echo "=== 7. RUNTIME STATE ==="
for file in \
    data/omega-memory.json \
    data/omega-state.json
do
    test -s "$file" \
        || fail "runtime state missing: $file"

    node -e '
        const fs = require("fs");
        const file = process.argv[1];
        JSON.parse(fs.readFileSync(file, "utf8"));
    ' "$file" \
        || fail "invalid JSON: $file"
done

pass "runtime state valid"

echo
echo "============================================================"
echo "          OMEGA® — POST RELEASE VERIFIED"
echo "============================================================"
echo
echo "[########################################] 100%"
echo
echo "PASS  PYTHON"
echo "PASS  RELEASE LOCK"
echo "PASS  MANIFEST"
echo "PASS  RELEASE SHA256"
echo "PASS  GITHUB SYNCHRONIZATION"
echo "PASS  PRODUCTION ARTIFACTS"
echo "PASS  RUNTIME STATE"
echo
echo "GIT HEAD:"
echo "  $LOCAL_HEAD"
echo
echo "BUILD ID:"
echo "  $BUILD_ID"
echo
echo "SERVER ARTIFACTS:"
echo "  $SERVER_FILES"
echo
echo "STATUS:"
echo "  OMEGA® PRODUCTION CERTIFIED"
echo "  HARDENED"
echo "  RELEASE LOCKED"
echo "  POST-RELEASE VERIFIED"
echo
echo "============================================================"
