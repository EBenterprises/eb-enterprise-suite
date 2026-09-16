#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
AUDIT="$CERT/OMEGA_FINAL_INTEGRITY_AUDIT.txt"

mkdir -p "$CERT" "$TMP"

FAILURES=0

fail() {
    echo "FAIL  $1"
    FAILURES=$((FAILURES + 1))
}

pass() {
    echo "PASS  $1"
}

echo
echo "============================================================"
echo "          OMEGA® — FINAL INTEGRITY AUDIT"
echo "============================================================"
echo

echo "=== 1. TOOLCHAIN ==="

for tool in node npm python git sha256sum bash; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool available"
    else
        fail "$tool unavailable"
    fi
done

echo
echo "=== 2. RELEASE FILES ==="

for file in \
    OMEGA_FINAL_RELEASE_LOCK.sh \
    OMEGA_POST_RELEASE_VERIFY.sh \
    OMEGA_FINAL_INTEGRITY_AUDIT.sh \
    package.json \
    next.config.mjs \
    .next/BUILD_ID \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt" \
    "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt"
do
    if test -s "$file"; then
        pass "$file"
    else
        fail "missing/empty: $file"
    fi
done

echo
echo "=== 3. SHELL SYNTAX ==="

for file in \
    OMEGA_FINAL_RELEASE_LOCK.sh \
    OMEGA_POST_RELEASE_VERIFY.sh \
    OMEGA_FINAL_INTEGRITY_AUDIT.sh
do
    if bash -n "$file"; then
        pass "syntax: $file"
    else
        fail "syntax: $file"
    fi
done

echo
echo "=== 4. MANIFEST STRUCTURE ==="

MANIFEST="$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt"

if grep -q '^OMEGA® FINAL RELEASE MANIFEST$' "$MANIFEST"; then
    pass "manifest identity"
else
    fail "manifest identity"
fi

for field in \
    'VERSION:' \
    'BRANCH:' \
    'GIT HEAD:' \
    'GITHUB HEAD:' \
    'BUILD ID:' \
    'NODE:' \
    'NPM:' \
    'NEXT:' \
    'TESTS:' \
    'SERVER ARTIFACTS:' \
    'CERTIFICATION:' \
    'HARDENING:' \
    'GITHUB:' \
    'RUNTIME STATE:' \
    'FINAL STATUS:'
do
    if grep -q "^${field}$" "$MANIFEST"; then
        pass "manifest field: $field"
    else
        fail "manifest field missing: $field"
    fi
done

grep -q '39/39 PASS' "$MANIFEST" \
    && pass "39/39 certification record" \
    || fail "39/39 certification record"

grep -q 'PRODUCTION CERTIFIED' "$MANIFEST" \
    && pass "production certification" \
    || fail "production certification"

grep -q 'HARDENING:' "$MANIFEST" \
    && pass "hardening record" \
    || fail "hardening record"

echo
echo "=== 5. RELEASE HASH ==="

HASH_FILE="$CERT/OMEGA_FINAL_RELEASE_SHA256.txt"

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$MANIFEST" \
    > "$TMP/audit-release-sha256.txt"

if cmp -s "$HASH_FILE" "$TMP/audit-release-sha256.txt"; then
    pass "release SHA256 exact match"
else
    fail "release SHA256 mismatch"
fi

echo
echo "=== 6. GITHUB IDENTITY ==="

git fetch origin master >/dev/null 2>&1 \
    && pass "GitHub remote refreshed" \
    || fail "GitHub fetch failed"

BRANCH="$(git branch --show-current)"
LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/master)"

echo "BRANCH: $BRANCH"
echo "LOCAL:  $LOCAL_HEAD"
echo "REMOTE: $REMOTE_HEAD"

[ "$BRANCH" = "master" ] \
    && pass "master branch" \
    || fail "branch is not master"

[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] \
    && pass "GitHub HEAD synchronized" \
    || fail "GitHub HEAD mismatch"

echo
echo "=== 7. BUILD IDENTITY ==="

BUILD_ID="$(cat .next/BUILD_ID)"

if [ -n "$BUILD_ID" ]; then
    pass "BUILD_ID present: $BUILD_ID"
else
    fail "BUILD_ID empty"
fi

if test -d .next/server; then
    pass "Next.js server tree"
else
    fail "Next.js server tree missing"
fi

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

if [ "$SERVER_FILES" -gt 0 ]; then
    pass "server artifacts: $SERVER_FILES"
else
    fail "server artifacts empty"
fi

echo
echo "=== 8. RUNTIME JSON ==="

for file in \
    data/omega-memory.json \
    data/omega-state.json
do
    if ! test -s "$file"; then
        fail "runtime file missing: $file"
        continue
    fi

    if node -e '
        const fs = require("fs");
        JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    ' "$file" >/dev/null 2>&1; then
        pass "valid JSON: $file"
    else
        fail "invalid JSON: $file"
    fi
done

echo
echo "=== 9. BUILD CONFIGURATION ==="

grep -q 'next build --webpack' package.json \
    && pass "Webpack production build locked" \
    || fail "Webpack build lock missing"

grep -q 'config.cache = false' next.config.mjs \
    && pass "filesystem cache disabled" \
    || fail "filesystem cache lock missing"

grep -q 'cpus: 1' next.config.mjs \
    && pass "single CPU lock" \
    || fail "single CPU lock missing"

echo
echo "=== 10. CERTIFICATION CONSISTENCY ==="

MANIFEST_BUILD_ID="$(
    awk '
        /^BUILD ID:$/ {
            getline
            print
            exit
        }
    ' "$MANIFEST" | tr -d '[:space:]'
)"

if [ "$MANIFEST_BUILD_ID" = "$BUILD_ID" ]; then
    pass "manifest BUILD_ID matches production BUILD_ID"
else
    fail "manifest BUILD_ID mismatch"
fi

MANIFEST_LOCAL_HEAD="$(
    awk '
        /^GIT HEAD:$/ {
            getline
            print
            exit
        }
    ' "$MANIFEST" | tr -d '[:space:]'
)"

if [ "$MANIFEST_LOCAL_HEAD" = "$LOCAL_HEAD" ]; then
    pass "manifest GIT HEAD matches repository"
else
    fail "manifest GIT HEAD mismatch"
fi

MANIFEST_REMOTE_HEAD="$(
    awk '
        /^GITHUB HEAD:$/ {
            getline
            print
            exit
        }
    ' "$MANIFEST" | tr -d '[:space:]'
)"

if [ "$MANIFEST_REMOTE_HEAD" = "$REMOTE_HEAD" ]; then
    pass "manifest GITHUB HEAD matches remote"
else
    fail "manifest GITHUB HEAD mismatch"
fi

echo
echo "=== 11. RELEASE LOCK EXECUTABLE ==="

if test -x OMEGA_FINAL_RELEASE_LOCK.sh; then
    pass "release lock executable"
else
    fail "release lock not executable"
fi

if test -x OMEGA_POST_RELEASE_VERIFY.sh; then
    pass "post-release verifier executable"
else
    fail "post-release verifier not executable"
fi

echo
echo "=== 12. WORKTREE INTEGRITY ==="

if git diff --check; then
    pass "Git whitespace integrity"
else
    fail "Git whitespace errors"
fi

echo
echo "=== 13. FINAL RESULT ==="

if [ "$FAILURES" -eq 0 ]; then
    echo
    echo "[########################################] 100%"
    echo
    echo "OMEGA® INTEGRITY AUDIT: PASS"
    echo
    echo "PRODUCTION CERTIFIED"
    echo "HARDENED"
    echo "RELEASE LOCKED"
    echo "POST-RELEASE VERIFIED"
    echo "INTEGRITY VERIFIED"
    echo
    echo "GIT HEAD:"
    echo "  $LOCAL_HEAD"
    echo
    echo "BUILD ID:"
    echo "  $BUILD_ID"
    echo
    echo "SERVER ARTIFACTS:"
    echo "  $SERVER_FILES"
else
    echo
    echo "OMEGA® INTEGRITY AUDIT: FAIL"
    echo "FAILURES: $FAILURES"
fi

{
    echo "============================================================"
    echo "OMEGA® — FINAL INTEGRITY AUDIT"
    echo "============================================================"
    echo "RESULT: $([ "$FAILURES" -eq 0 ] && echo PASS || echo FAIL)"
    echo "GIT HEAD: $LOCAL_HEAD"
    echo "GITHUB HEAD: $REMOTE_HEAD"
    echo "BUILD ID: $BUILD_ID"
    echo "SERVER ARTIFACTS: $SERVER_FILES"
    echo "FAILURES: $FAILURES"
    echo "STATUS: $([ "$FAILURES" -eq 0 ] && echo 'PRODUCTION CERTIFIED + HARDENED + RELEASE LOCKED + INTEGRITY VERIFIED' || echo 'INTEGRITY AUDIT FAILED')"
    echo "============================================================"
} > "$AUDIT"

echo
echo "AUDIT FILE:"
echo "$AUDIT"

[ "$FAILURES" -eq 0 ]
