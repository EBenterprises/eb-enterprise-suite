#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"

mkdir -p "$CERT" "$TMP"

fail() {
    echo
    echo "============================================================"
    echo "FAIL — $1"
    echo "============================================================"
    exit 1
}

pass() {
    echo "PASS  $1"
}

echo
echo "============================================================"
echo "          OMEGA® — FINAL RELEASE LOCK"
echo "============================================================"
echo

# ============================================================
# 1. REPOSITORY IDENTITY
# ============================================================

echo "=== 1. REPOSITORY IDENTITY ==="

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "not a git repository"

BRANCH="$(git branch --show-current)"
[ "$BRANCH" = "master" ] \
    || fail "branch is not master"

git fetch origin master >/dev/null 2>&1 \
    || fail "GitHub fetch failed"

LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/master)"

echo "BRANCH: $BRANCH"
echo "LOCAL:  $LOCAL_HEAD"
echo "REMOTE: $REMOTE_HEAD"

[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] \
    || fail "local and GitHub HEAD differ"

pass "repository synchronized"

# ============================================================
# 2. RELEASE ARTIFACTS
# ============================================================

echo
echo "=== 2. RELEASE ARTIFACTS ==="

test -s "$CERT/OMEGA_CERTIFIED.txt" \
    || fail "OMEGA_CERTIFIED.txt missing"

test -s "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    || fail "OMEGA_RELEASE_FINGERPRINT.txt missing"

test -s "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    || fail "OMEGA_CERTIFICATION_SHA256.txt missing"

pass "certification artifacts"

# ============================================================
# 3. CERTIFICATION HASH VERIFICATION
# ============================================================

echo
echo "=== 3. CERTIFICATION HASH VERIFICATION ==="

(
    cd "$CERT"
    sha256sum -c OMEGA_CERTIFICATION_SHA256.txt
) > "$TMP/final-hash-check.log" 2>&1 \
    || {
        cat "$TMP/final-hash-check.log"
        fail "certification SHA256 verification"
    }

pass "certification hashes verified"

# ============================================================
# 4. CLI
# ============================================================

echo
echo "=== 4. CLI ==="

node --check bin/omega.js \
    || fail "CLI syntax"

node bin/omega.js status >/dev/null \
    || fail "CLI status"

node bin/omega.js capabilities >/dev/null \
    || fail "CLI capabilities"

node bin/omega.js metrics >/dev/null \
    || fail "CLI metrics"

node bin/omega.js help >/dev/null \
    || fail "CLI help"

pass "CLI operational"

# ============================================================
# 5. METRICS CONTRACT
# ============================================================

echo
echo "=== 5. METRICS CONTRACT ==="

METRICS_OUTPUT="$(node bin/omega.js metrics)"

printf '%s\n' "$METRICS_OUTPUT" | node -e '
let data = "";

process.stdin.on("data", chunk => {
    data += chunk;
});

process.stdin.on("end", () => {
    try {
        const value = JSON.parse(data);

        if (
            value === null ||
            typeof value !== "object" ||
            Array.isArray(value)
        ) {
            process.exit(1);
        }
    } catch {
        process.exit(1);
    }
});
' || fail "metrics JSON contract"

pass "metrics JSON contract"

# ============================================================
# 6. TEST SUITE
# ============================================================

echo
echo "=== 6. TEST SUITE ==="

if ! npm test > "$TMP/final-release-tests.log" 2>&1; then
    tail -200 "$TMP/final-release-tests.log"
    fail "npm test"
fi

grep -Eq 'fail[[:space:]]+0' "$TMP/final-release-tests.log" \
    || fail "fail count is not zero"

grep -Eq 'pass[[:space:]]+39' "$TMP/final-release-tests.log" \
    || fail "39 passing tests not confirmed"

pass "39/39 tests"

# ============================================================
# 7. PRODUCTION ARTIFACTS
# ============================================================

echo
echo "=== 7. PRODUCTION ARTIFACTS ==="

test -s .next/BUILD_ID \
    || fail "BUILD_ID missing"

test -s .next/server/pages-manifest.json \
    || fail "pages-manifest missing"

test -s .next/server/app/page.js \
    || fail "server page missing"

test -s .next/server/app/_not-found/page.js.nft.json \
    || fail "_not-found NFT missing"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

[ "$SERVER_FILES" -gt 0 ] \
    || fail "server artifact tree empty"

BUILD_ID="$(cat .next/BUILD_ID)"

echo "BUILD_ID: $BUILD_ID"
echo "SERVER ARTIFACTS: $SERVER_FILES"

pass "production artifacts"

# ============================================================
# 8. TERMUX BUILD LOCK
# ============================================================

echo
echo "=== 8. TERMUX BUILD LOCK ==="

grep -q 'config.cache = false' next.config.mjs \
    || fail "webpack filesystem cache lock missing"

grep -q 'cpus: 1' next.config.mjs \
    || fail "single CPU lock missing"

grep -q '"build": "next build --webpack"' package.json \
    || fail "Webpack build command missing"

pass "Termux build configuration locked"

# ============================================================
# 9. SOURCE SYNTAX
# ============================================================

echo
echo "=== 9. SOURCE SYNTAX ==="

SOURCE_FAIL=0

while IFS= read -r file; do
    if ! node --check "$file" >/dev/null 2>&1; then
        echo "FAIL  syntax: $file"
        SOURCE_FAIL=1
    fi
done < <(
    find src \
        -type f \
        \( -name "*.js" -o -name "*.mjs" \) \
        ! -path "src/app/*" \
        -print
)

[ "$SOURCE_FAIL" -eq 0 ] \
    || fail "core JavaScript syntax"

pass "core JavaScript syntax"

# ============================================================
# 10. WORKTREE POLICY
# ============================================================

echo
echo "=== 10. WORKTREE POLICY ==="

git diff --check \
    || fail "whitespace errors"

RUNTIME_CHANGES="$(git status --short -- \
    data/omega-memory.json \
    data/omega-state.json || true)"

RELEASE_SCRIPT_CHANGES="$(git status --short -- \
    OMEGA_FINALIZE_HARDENING.sh || true)"

if [ -n "$RUNTIME_CHANGES" ]; then
    echo "RUNTIME STATE:"
    echo "$RUNTIME_CHANGES"
    pass "runtime state preserved"
else
    pass "runtime state clean"
fi

if [ -n "$RELEASE_SCRIPT_CHANGES" ]; then
    echo "$RELEASE_SCRIPT_CHANGES"
    pass "release script present as local work"
else
    pass "release script tracked/clean"
fi

# ============================================================
# 11. RELEASE MANIFEST
# ============================================================

echo
echo "=== 11. RELEASE MANIFEST ==="

VERSION="$(node -p 'JSON.parse(require("fs").readFileSync("package.json","utf8")).version')"
NODE_VERSION="$(node --version)"
NPM_VERSION="$(npm --version)"
NEXT_VERSION="$(node -p 'require("next/package.json").version')"

cat > "$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt" <<MANIFEST
============================================================
OMEGA® FINAL RELEASE MANIFEST
============================================================

PROJECT:
OMEGA®

VERSION:
$VERSION

BRANCH:
$BRANCH

GIT HEAD:
$LOCAL_HEAD

GITHUB HEAD:
$REMOTE_HEAD

BUILD ID:
$BUILD_ID

NODE:
$NODE_VERSION

NPM:
$NPM_VERSION

NEXT:
$NEXT_VERSION

BUILD:
Next.js + Webpack

TERMUX MODE:
Single CPU
Filesystem cache disabled

TESTS:
39/39 PASS
fail: 0

SERVER ARTIFACTS:
$SERVER_FILES

CERTIFICATION:
PRODUCTION CERTIFIED

HARDENING:
COMPLETE

GITHUB:
SYNCHRONIZED

RUNTIME STATE:
Preserved

FINAL STATUS:
OMEGA® PRODUCTION CERTIFIED + HARDENED

============================================================
END OF MANIFEST
============================================================
MANIFEST

test -s "$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt" \
    || fail "release manifest missing"

pass "final release manifest"

# ============================================================
# 12. RELEASE HASH
# ============================================================

echo
echo "=== 12. RELEASE HASH ==="

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt" \
    > "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt"

test -s "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt" \
    || fail "final release SHA256 missing"

pass "final release SHA256 generated"

# ============================================================
# 13. FINAL REPORT
# ============================================================

echo
echo "============================================================"
echo "              OMEGA® — RELEASE LOCKED"
echo "============================================================"
echo
echo "[########################################] 100%"
echo
echo "PASS  REPOSITORY"
echo "PASS  GITHUB SYNCHRONIZATION"
echo "PASS  CERTIFICATION"
echo "PASS  CERTIFICATION HASHES"
echo "PASS  CLI"
echo "PASS  METRICS CONTRACT"
echo "PASS  39/39 TESTS"
echo "PASS  PRODUCTION ARTIFACTS"
echo "PASS  TERMUX BUILD LOCK"
echo "PASS  SOURCE SYNTAX"
echo "PASS  RUNTIME STATE POLICY"
echo "PASS  RELEASE MANIFEST"
echo "PASS  RELEASE SHA256"
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
echo "  OMEGA® PRODUCTION CERTIFIED + HARDENED + RELEASE LOCKED"
echo
echo "============================================================"
