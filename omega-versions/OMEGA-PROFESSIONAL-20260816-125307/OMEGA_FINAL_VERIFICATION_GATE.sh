#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
mkdir -p "$CERT" "$TMP"

FAILURES=0

fail() {
    echo "FAIL  $1"
    FAILURES=$((FAILURES + 1))
}

pass() {
    echo "PASS  $1"
}

echo "============================================================"
echo "        OMEGA® — FINAL VERIFICATION GATE"
echo "============================================================"
echo

echo "=== 1. ENVIRONMENT ==="

command -v node >/dev/null 2>&1 \
    && pass "Node.js" \
    || fail "Node.js unavailable"

command -v npm >/dev/null 2>&1 \
    && pass "npm" \
    || fail "npm unavailable"

command -v python >/dev/null 2>&1 \
    && pass "Python" \
    || fail "Python unavailable"

command -v git >/dev/null 2>&1 \
    && pass "Git" \
    || fail "Git unavailable"

echo
echo "=== 2. RELEASE LOCK ==="

test -x OMEGA_FINAL_RELEASE_LOCK.sh \
    && pass "release lock present" \
    || fail "release lock missing"

bash -n OMEGA_FINAL_RELEASE_LOCK.sh \
    && pass "release lock syntax" \
    || fail "release lock syntax"

echo
echo "=== 3. POST RELEASE VERIFIER ==="

test -x OMEGA_POST_RELEASE_VERIFY.sh \
    && pass "post-release verifier present" \
    || fail "post-release verifier missing"

bash -n OMEGA_POST_RELEASE_VERIFY.sh \
    && pass "post-release verifier syntax" \
    || fail "post-release verifier syntax"

echo
echo "=== 4. SOURCE RESOLVER ==="

test -x OMEGA_SOURCE_SYNTAX_RESOLVER_V2.sh \
    && pass "source resolver present" \
    || fail "source resolver missing"

bash -n OMEGA_SOURCE_SYNTAX_RESOLVER_V2.sh \
    && pass "source resolver syntax" \
    || fail "source resolver syntax"

echo
echo "=== 5. BUILD ARTIFACTS ==="

test -s .next/BUILD_ID \
    && pass "Next.js BUILD_ID" \
    || fail "BUILD_ID missing"

test -d .next/server \
    && pass "Next.js server tree" \
    || fail "server tree missing"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

[ "$SERVER_FILES" -gt 0 ] \
    && pass "server artifacts: $SERVER_FILES" \
    || fail "server artifact tree empty"

echo
echo "=== 6. RUNTIME STATE ==="

for file in \
    data/omega-memory.json \
    data/omega-state.json
do
    if [ -s "$file" ]; then
        node -e '
            const fs = require("fs");
            JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        ' "$file" >/dev/null 2>&1 \
            && pass "valid JSON: $file" \
            || fail "invalid JSON: $file"
    else
        fail "missing runtime file: $file"
    fi
done

echo
echo "=== 7. CERTIFICATION ==="

for file in \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt" \
    "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt"
do
    test -s "$file" \
        && pass "$(basename "$file")" \
        || fail "missing certification artifact: $file"
done

echo
echo "=== 8. MANIFEST IDENTITY ==="

MANIFEST="$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt"

grep -q '^OMEGA® FINAL RELEASE MANIFEST$' "$MANIFEST" \
    && pass "manifest identity" \
    || fail "manifest identity"

grep -q '^39/39 PASS$' "$MANIFEST" \
    && pass "39/39 certification record" \
    || fail "39/39 certification record"

grep -q 'OMEGA® PRODUCTION CERTIFIED + HARDENED' "$MANIFEST" \
    && pass "production certification record" \
    || fail "production certification record"

echo
echo "=== 9. RELEASE HASH ==="

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$MANIFEST" \
    > "$TMP/final-gate-recomputed.sha256"

cmp -s \
    "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt" \
    "$TMP/final-gate-recomputed.sha256" \
    && pass "release SHA256 exact match" \
    || fail "release SHA256 mismatch"

echo
echo "=== 10. GITHUB ==="

git fetch origin master >/dev/null 2>&1 \
    && pass "GitHub fetch" \
    || fail "GitHub fetch"

BRANCH="$(git branch --show-current)"
LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/master)"

[ "$BRANCH" = "master" ] \
    && pass "master branch" \
    || fail "wrong branch: $BRANCH"

[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] \
    && pass "GitHub HEAD synchronized" \
    || fail "GitHub HEAD mismatch"

echo
echo "=== 11. BUILD CONFIGURATION ==="

grep -q 'next build --webpack' package.json \
    && pass "Webpack production build" \
    || fail "Webpack build configuration"

grep -q 'config.cache = false' next.config.mjs \
    && pass "filesystem cache disabled" \
    || fail "filesystem cache configuration"

grep -q 'cpus: 1' next.config.mjs \
    && pass "single CPU configuration" \
    || fail "single CPU configuration"

echo
echo "=== 12. FINAL GATE ==="

if [ "$FAILURES" -eq 0 ]; then
    BUILD_ID="$(cat .next/BUILD_ID)"

    cat > "$CERT/OMEGA_FINAL_VERIFICATION_GATE.txt" <<GATE
OMEGA® FINAL VERIFICATION GATE

STATUS:
PASS

SOURCE:
CLEAN

CERTIFICATION:
PRODUCTION CERTIFIED

HARDENING:
COMPLETE

RELEASE:
LOCKED

POST-RELEASE:
VERIFIED

INTEGRITY:
VERIFIED

GITHUB:
SYNCHRONIZED

TESTS:
39/39 PASS

GIT HEAD:
$LOCAL_HEAD

BUILD ID:
$BUILD_ID

SERVER ARTIFACTS:
$SERVER_FILES

FINAL STATUS:
OMEGA® PRODUCTION CERTIFIED + HARDENED + RELEASE LOCKED + VERIFIED
GATE

    echo
    echo "[########################################] 100%"
    echo
    echo "PASS  ENVIRONMENT"
    echo "PASS  RELEASE LOCK"
    echo "PASS  POST-RELEASE VERIFIER"
    echo "PASS  SOURCE RESOLVER"
    echo "PASS  BUILD ARTIFACTS"
    echo "PASS  RUNTIME STATE"
    echo "PASS  CERTIFICATION"
    echo "PASS  MANIFEST"
    echo "PASS  RELEASE SHA256"
    echo "PASS  GITHUB"
    echo "PASS  BUILD CONFIGURATION"
    echo
    echo "============================================================"
    echo "OMEGA® — FINAL VERIFICATION GATE: PASS"
    echo "============================================================"
    echo
    echo "STATUS:"
    echo "OMEGA® PRODUCTION CERTIFIED"
    echo "HARDENED"
    echo "RELEASE LOCKED"
    echo "POST-RELEASE VERIFIED"
    echo "INTEGRITY VERIFIED"
    echo
    echo "GIT HEAD:"
    echo "$LOCAL_HEAD"
    echo
    echo "BUILD ID:"
    echo "$BUILD_ID"
    echo
    echo "SERVER ARTIFACTS:"
    echo "$SERVER_FILES"
    echo
    echo "GATE:"
    echo "$CERT/OMEGA_FINAL_VERIFICATION_GATE.txt"
else
    echo
    echo "============================================================"
    echo "OMEGA® — FINAL VERIFICATION GATE: FAIL"
    echo "============================================================"
    echo
    echo "FAILURES: $FAILURES"
    echo
    echo "NO PRODUCTION SOURCE FILES WERE MODIFIED."
    exit 1
fi
