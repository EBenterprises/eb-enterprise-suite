#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TMP="$ROOT/.omega/tmp"
CERT="$ROOT/.omega/certification"
mkdir -p "$TMP" "$CERT"

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
echo "       OMEGA® — POST-CERTIFICATION HARDENING"
echo "============================================================"
echo
echo "ROOT: $ROOT"
echo "DATE: $(date)"
echo

# ============================================================
# 1. REPOSITORY STATE
# ============================================================

echo "=== 1. REPOSITORY STATE ==="

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "not a git repository"

BRANCH="$(git branch --show-current)"
HEAD="$(git rev-parse HEAD)"
ORIGIN_HEAD="$(git rev-parse origin/master 2>/dev/null || echo "UNAVAILABLE")"

echo "BRANCH: $BRANCH"
echo "HEAD:   $HEAD"
echo "ORIGIN: $ORIGIN_HEAD"

[ "$BRANCH" = "master" ] \
    || fail "expected master branch"

[ "$HEAD" = "$ORIGIN_HEAD" ] \
    || fail "local HEAD differs from origin/master"

pass "master synchronized with GitHub"

# ============================================================
# 2. WORKTREE AUDIT
# ============================================================

echo
echo "=== 2. WORKTREE AUDIT ==="

git status --short | tee "$TMP/post-certification-status.log"

DATA_CHANGES="$(git status --short -- data/omega-memory.json data/omega-state.json || true)"

if [ -n "$DATA_CHANGES" ]; then
    echo
    echo "RUNTIME DATA CHANGES DETECTED:"
    echo "$DATA_CHANGES"
    echo
    echo "These files are treated as runtime state."
    echo "They will NOT be committed automatically."
else
    pass "runtime data clean"
fi

git diff --check \
    || fail "whitespace errors"

pass "git diff check"

# ============================================================
# 3. CERTIFICATE INTEGRITY
# ============================================================

echo
echo "=== 3. CERTIFICATE INTEGRITY ==="

CERT_FILE="$CERT/OMEGA_CERTIFIED.txt"

test -s "$CERT_FILE" \
    || fail "certificate missing"

grep -q "OMEGA® FINAL CERTIFICATION" "$CERT_FILE" \
    || fail "certificate header missing"

grep -q "STATUS" "$CERT_FILE" \
    || fail "certificate status missing"

grep -q "CERTIFIED" "$CERT_FILE" \
    || fail "certificate is not certified"

pass "certificate integrity"

# ============================================================
# 4. CERTIFIED COMMIT
# ============================================================

echo
echo "=== 4. CERTIFIED COMMIT ==="

git show --stat --oneline --decorate HEAD

git show --format= --name-only HEAD | grep -qx "bin/omega.js" \
    || fail "certified commit missing bin/omega.js"

git show --format= --name-only HEAD | grep -qx "next.config.mjs" \
    || fail "certified commit missing next.config.mjs"

git show --format= --name-only HEAD | grep -qx "OMEGA_FINAL_REPAIR_CERTIFY.sh" \
    || fail "certified commit missing certification script"

pass "certification commit contents verified"

# ============================================================
# 5. CLI CONTRACT RECHECK
# ============================================================

echo
echo "=== 5. CLI CONTRACT RECHECK ==="

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

pass "CLI contract"

# ============================================================
# 6. METRICS JSON CONTRACT
# ============================================================

echo
echo "=== 6. METRICS JSON CONTRACT ==="

METRICS_OUTPUT="$(node bin/omega.js metrics)"

printf '%s\n' "$METRICS_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", chunk => data += chunk);
process.stdin.on("end", () => {
    const value = JSON.parse(data);

    if (
        value === null ||
        typeof value !== "object" ||
        Array.isArray(value)
    ) {
        process.exit(1);
    }
});
' || fail "metrics JSON contract"

pass "metrics JSON"

# ============================================================
# 7. TEST SUITE
# ============================================================

echo
echo "=== 7. TEST SUITE ==="

if ! npm test > "$TMP/post-certification-tests.log" 2>&1; then
    echo
    tail -160 "$TMP/post-certification-tests.log"
    fail "npm test"
fi

grep -Eq 'fail[[:space:]]+0' "$TMP/post-certification-tests.log" \
    || fail "test suite fail count"

grep -Eq 'pass[[:space:]]+39' "$TMP/post-certification-tests.log" \
    || fail "39 passing tests not confirmed"

pass "39/39 tests"

# ============================================================
# 8. PRODUCTION ARTIFACT RECHECK
# ============================================================

echo
echo "=== 8. PRODUCTION ARTIFACT RECHECK ==="

test -s .next/BUILD_ID \
    || fail "BUILD_ID"

test -s .next/server/pages-manifest.json \
    || fail "pages-manifest"

test -s .next/server/app/page.js \
    || fail "application server page"

test -s .next/server/app/_not-found/page.js.nft.json \
    || fail "_not-found NFT"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

[ "$SERVER_FILES" -gt 0 ] \
    || fail "server artifact tree empty"

echo "SERVER ARTIFACTS: $SERVER_FILES"

pass "production artifacts"

# ============================================================
# 9. BUILD CONFIGURATION LOCK
# ============================================================

echo
echo "=== 9. BUILD CONFIGURATION LOCK ==="

grep -q 'config.cache = false' next.config.mjs \
    || fail "webpack cache disabled configuration missing"

grep -q 'cpus: 1' next.config.mjs \
    || fail "single CPU configuration missing"

grep -q '"build": "next build --webpack"' package.json \
    || fail "webpack production build command missing"

pass "Termux production build configuration locked"

# ============================================================
# 10. SOURCE SYNTAX
# ============================================================

echo
echo "=== 10. SOURCE SYNTAX ==="

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
pass "src/app JSX delegated to Next.js compiler"

# ============================================================
# 11. RELEASE FINGERPRINT
# ============================================================

echo
echo "=== 11. RELEASE FINGERPRINT ==="

VERSION="$(node -p 'JSON.parse(require("fs").readFileSync("package.json","utf8")).version')"
BUILD_ID="$(cat .next/BUILD_ID)"
NODE_VERSION="$(node --version)"
NPM_VERSION="$(npm --version)"
NEXT_VERSION="$(node -p 'require("next/package.json").version')"

cat > "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" <<FINGERPRINT
OMEGA® RELEASE FINGERPRINT
==========================

PROJECT: OMEGA®
VERSION: $VERSION

GIT:
$HEAD

ORIGIN:
$ORIGIN_HEAD

BUILD_ID:
$BUILD_ID

NODE:
$NODE_VERSION

NPM:
$NPM_VERSION

NEXT:
$NEXT_VERSION

BUILD:
Next.js + Webpack
Single CPU
Filesystem cache disabled

TESTS:
39/39 PASS

SERVER_ARTIFACTS:
$SERVER_FILES

STATUS:
PRODUCTION CERTIFIED
FINGERPRINT

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    > "$CERT/OMEGA_CERTIFICATION_SHA256.txt"

pass "release fingerprint generated"

# ============================================================
# 12. FINAL GIT AUDIT
# ============================================================

echo
echo "=== 12. FINAL GIT AUDIT ==="

git diff --check \
    || fail "final git diff check"

echo
echo "CURRENT WORKTREE:"
git status --short

echo
echo "CERTIFIED HEAD:"
git rev-parse HEAD

echo
echo "REMOTE MASTER:"
git rev-parse origin/master

[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/master)" ] \
    || fail "GitHub synchronization lost"

pass "GitHub synchronization verified"

# ============================================================
# FINAL
# ============================================================

echo
echo "============================================================"
echo "       OMEGA® — POST-CERTIFICATION HARDENED"
echo "============================================================"
echo
echo "[########################################] 100%"
echo
echo "PASS  REPOSITORY"
echo "PASS  CERTIFICATE"
echo "PASS  CERTIFIED COMMIT"
echo "PASS  CLI CONTRACT"
echo "PASS  METRICS CONTRACT"
echo "PASS  39/39 TESTS"
echo "PASS  PRODUCTION ARTIFACTS"
echo "PASS  BUILD CONFIGURATION"
echo "PASS  SOURCE SYNTAX"
echo "PASS  RELEASE FINGERPRINT"
echo "PASS  GITHUB SYNCHRONIZATION"
echo
echo "OMEGA® STATUS: PRODUCTION CERTIFIED + HARDENED"
echo
echo "CERTIFICATE:"
echo "  $CERT/OMEGA_CERTIFIED.txt"
echo
echo "FINGERPRINT:"
echo "  $CERT/OMEGA_RELEASE_FINGERPRINT.txt"
echo
echo "SHA256:"
echo "  $CERT/OMEGA_CERTIFICATION_SHA256.txt"
echo
echo "============================================================"
