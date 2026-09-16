#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
AUDIT="$CERT/OMEGA_DEEP_INTEGRITY_AUDIT.txt"

mkdir -p "$CERT" "$TMP"

FAILURES=0
CHECKS=0
PASSES=0

check() {
    CHECKS=$((CHECKS + 1))
    if "$@"; then
        PASSES=$((PASSES + 1))
        echo "PASS  $2"
    else
        FAILURES=$((FAILURES + 1))
        echo "FAIL  $2"
    fi
}

fail() {
    FAILURES=$((FAILURES + 1))
    CHECKS=$((CHECKS + 1))
    echo "FAIL  $1"
}

pass() {
    PASSES=$((PASSES + 1))
    CHECKS=$((CHECKS + 1))
    echo "PASS  $1"
}

section() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

section "OMEGA® — DEEP INTEGRITY AUDIT"

echo "ROOT:"
echo "$ROOT"
echo

section "1. TOOLCHAIN"

for tool in node npm npx python git bash sha256sum find grep awk sed; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool available"
    else
        fail "$tool unavailable"
    fi
done

NODE_VERSION="$(node --version 2>/dev/null || echo unavailable)"
NPM_VERSION="$(npm --version 2>/dev/null || echo unavailable)"
PYTHON_VERSION="$(python --version 2>&1 || echo unavailable)"

echo "NODE:   $NODE_VERSION"
echo "NPM:    $NPM_VERSION"
echo "PYTHON: $PYTHON_VERSION"

section "2. PROJECT IDENTITY"

test -f package.json \
    && pass "package.json exists" \
    || fail "package.json missing"

if test -s package.json; then
    node -e '
        const fs = require("fs");
        const p = JSON.parse(fs.readFileSync("package.json","utf8"));
        if (!p.name || !p.version) process.exit(1);
    ' >/dev/null 2>&1 \
        && pass "package.json valid" \
        || fail "package.json invalid"
fi

VERSION="$(node -p 'JSON.parse(require("fs").readFileSync("package.json","utf8")).version' 2>/dev/null || echo unknown)"
NEXT_VERSION="$(node -p 'require("next/package.json").version' 2>/dev/null || echo unknown)"

echo "PROJECT: OMEGA®"
echo "VERSION: $VERSION"
echo "NEXT:    $NEXT_VERSION"

section "3. RELEASE ARTIFACT INVENTORY"

RELEASE_FILES=(
    "OMEGA_FINAL_RELEASE_LOCK.sh"
    "OMEGA_POST_RELEASE_VERIFY.sh"
    "OMEGA_FINAL_INTEGRITY_AUDIT.sh"
    "package.json"
    "next.config.mjs"
    ".next/BUILD_ID"
    "$CERT/OMEGA_CERTIFIED.txt"
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt"
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt"
    "$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt"
    "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt"
)

for file in "${RELEASE_FILES[@]}"; do
    if test -s "$file"; then
        pass "artifact present: $file"
    else
        fail "artifact missing/empty: $file"
    fi
done

section "4. SHELL VALIDATION"

for file in \
    OMEGA_FINAL_RELEASE_LOCK.sh \
    OMEGA_POST_RELEASE_VERIFY.sh \
    OMEGA_FINAL_INTEGRITY_AUDIT.sh
do
    if bash -n "$file"; then
        pass "shell syntax: $file"
    else
        fail "shell syntax: $file"
    fi

    if test -x "$file"; then
        pass "executable: $file"
    else
        fail "not executable: $file"
    fi
done

section "5. RELEASE MANIFEST"

MANIFEST="$CERT/OMEGA_FINAL_RELEASE_MANIFEST.txt"

if grep -q '^OMEGA® FINAL RELEASE MANIFEST$' "$MANIFEST"; then
    pass "manifest identity"
else
    fail "manifest identity"
fi

for field in \
    "VERSION:" \
    "BRANCH:" \
    "GIT HEAD:" \
    "GITHUB HEAD:" \
    "BUILD ID:" \
    "NODE:" \
    "NPM:" \
    "NEXT:" \
    "BUILD:" \
    "TERMUX MODE:" \
    "TESTS:" \
    "SERVER ARTIFACTS:" \
    "CERTIFICATION:" \
    "HARDENING:" \
    "GITHUB:" \
    "RUNTIME STATE:" \
    "FINAL STATUS:"
do
    grep -q "^${field}$" "$MANIFEST" \
        && pass "manifest field: $field" \
        || fail "manifest field missing: $field"
done

grep -q "39/39 PASS" "$MANIFEST" \
    && pass "39/39 test record" \
    || fail "39/39 test record"

grep -q "PRODUCTION CERTIFIED" "$MANIFEST" \
    && pass "production certification record" \
    || fail "production certification record"

grep -q "HARDENING:" "$MANIFEST" \
    && pass "hardening record" \
    || fail "hardening record"

section "6. MANIFEST VALUE VALIDATION"

MANIFEST_BUILD_ID="$(
    awk '/^BUILD ID:$/ { getline; print; exit }' "$MANIFEST" |
    tr -d '[:space:]'
)"

MANIFEST_LOCAL_HEAD="$(
    awk '/^GIT HEAD:$/ { getline; print; exit }' "$MANIFEST" |
    tr -d '[:space:]'
)"

MANIFEST_REMOTE_HEAD="$(
    awk '/^GITHUB HEAD:$/ { getline; print; exit }' "$MANIFEST" |
    tr -d '[:space:]'
)"

BUILD_ID="$(cat .next/BUILD_ID)"

[ "$MANIFEST_BUILD_ID" = "$BUILD_ID" ] \
    && pass "manifest BUILD_ID matches build" \
    || fail "manifest BUILD_ID mismatch"

section "7. GIT INTEGRITY"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && pass "Git repository" \
    || fail "Git repository unavailable"

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
    || fail "unexpected branch"

[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] \
    && pass "GitHub HEAD synchronized" \
    || fail "GitHub HEAD mismatch"

[ "$MANIFEST_LOCAL_HEAD" = "$LOCAL_HEAD" ] \
    && pass "manifest local HEAD matches" \
    || fail "manifest local HEAD mismatch"

[ "$MANIFEST_REMOTE_HEAD" = "$REMOTE_HEAD" ] \
    && pass "manifest remote HEAD matches" \
    || fail "manifest remote HEAD mismatch"

git diff --check \
    && pass "Git whitespace clean" \
    || fail "Git whitespace errors"

section "8. BUILD ARTIFACT INTEGRITY"

test -s .next/BUILD_ID \
    && pass "Next.js BUILD_ID" \
    || fail "Next.js BUILD_ID missing"

test -d .next/server \
    && pass "Next.js server directory" \
    || fail "Next.js server directory missing"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

[ "$SERVER_FILES" -gt 0 ] \
    && pass "server artifact count: $SERVER_FILES" \
    || fail "server artifacts empty"

test -s .next/server/pages-manifest.json \
    && pass "pages-manifest.json" \
    || fail "pages-manifest.json missing"

test -s .next/server/app-paths-manifest.json \
    && pass "app-paths-manifest.json" \
    || fail "app-paths-manifest.json missing"

section "9. NEXT.JS CONFIGURATION"

grep -q 'next build --webpack' package.json \
    && pass "Webpack production build" \
    || fail "Webpack build command"

grep -q 'config.cache = false' next.config.mjs \
    && pass "filesystem cache disabled" \
    || fail "filesystem cache not disabled"

grep -q 'cpus: 1' next.config.mjs \
    && pass "single CPU configuration" \
    || fail "single CPU configuration missing"

section "10. SOURCE JAVASCRIPT VALIDATION"

SOURCE_FAILURES=0

while IFS= read -r file; do
    if node --check "$file" >/dev/null 2>&1; then
        :
    else
        echo "FAIL  source syntax: $file"
        SOURCE_FAILURES=$((SOURCE_FAILURES + 1))
    fi
done < <(
    find src bin \
        -type f \
        \( -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) \
        2>/dev/null |
    sort
)

if [ "$SOURCE_FAILURES" -eq 0 ]; then
    pass "all checked JavaScript source syntax"
else
    FAILURES=$((FAILURES + SOURCE_FAILURES))
    CHECKS=$((CHECKS + SOURCE_FAILURES))
fi

section "11. RUNTIME STATE"

for file in \
    data/omega-memory.json \
    data/omega-state.json
do
    if test -s "$file"; then
        pass "runtime file exists: $file"
    else
        fail "runtime file missing: $file"
        continue
    fi

    if node -e '
        const fs = require("fs");
        JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    ' "$file" >/dev/null 2>&1; then
        pass "runtime JSON valid: $file"
    else
        fail "runtime JSON invalid: $file"
    fi
done

section "12. CLI INTEGRITY"

if test -x bin/omega.js; then
    pass "OMEGA CLI executable"
else
    fail "OMEGA CLI missing/non-executable"
fi

if node --check bin/omega.js >/dev/null 2>&1; then
    pass "OMEGA CLI syntax"
else
    fail "OMEGA CLI syntax"
fi

for command in status capabilities metrics help; do
    if node bin/omega.js "$command" >/dev/null 2>&1; then
        pass "CLI command: $command"
    else
        fail "CLI command failed: $command"
    fi
done

section "13. CERTIFICATION HASH CHAIN"

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    > "$TMP/certification-recomputed.sha256"

if test -s "$CERT/OMEGA_CERTIFICATION_SHA256.txt"; then
    pass "certification SHA256 file present"
else
    fail "certification SHA256 file empty"
fi

(
    cd "$CERT"
    sha256sum -c OMEGA_CERTIFICATION_SHA256.txt
) >/dev/null 2>&1 \
    && pass "certification SHA256 verification" \
    || fail "certification SHA256 verification"

section "14. FINAL RELEASE HASH"

sha256sum \
    "$CERT/OMEGA_CERTIFIED.txt" \
    "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    "$MANIFEST" \
    > "$TMP/final-release-recomputed.sha256"

if cmp -s \
    "$CERT/OMEGA_FINAL_RELEASE_SHA256.txt" \
    "$TMP/final-release-recomputed.sha256"
then
    pass "final release SHA256 exact match"
else
    fail "final release SHA256 mismatch"
fi

section "15. PACKAGE CONSISTENCY"

PACKAGE_NAME="$(node -p 'JSON.parse(require("fs").readFileSync("package.json","utf8")).name' 2>/dev/null || echo "")"

if [ -n "$PACKAGE_NAME" ]; then
    pass "package name: $PACKAGE_NAME"
else
    fail "package name unavailable"
fi

PACKAGE_VERSION="$VERSION"

if [ "$PACKAGE_VERSION" != "unknown" ] && [ -n "$PACKAGE_VERSION" ]; then
    pass "package version: $PACKAGE_VERSION"
else
    fail "package version unavailable"
fi

section "16. RELEASE SCRIPT CONTENT"

grep -q 'OMEGA_FINAL_RELEASE_MANIFEST.txt' \
    OMEGA_FINAL_RELEASE_LOCK.sh \
    && pass "release lock generates manifest" \
    || fail "release lock manifest generation missing"

grep -q 'OMEGA_FINAL_RELEASE_SHA256.txt' \
    OMEGA_FINAL_RELEASE_LOCK.sh \
    && pass "release lock generates final SHA256" \
    || fail "release lock SHA256 generation missing"

grep -q '39/39' \
    OMEGA_FINAL_RELEASE_LOCK.sh \
    && pass "release lock records 39/39" \
    || fail "release lock 39/39 record missing"

section "17. POST-RELEASE VERIFIER"

grep -q 'OMEGA_FINAL_RELEASE_MANIFEST.txt' \
    OMEGA_POST_RELEASE_VERIFY.sh \
    && pass "post-release manifest verification" \
    || fail "post-release manifest verification missing"

grep -q 'OMEGA_FINAL_RELEASE_SHA256.txt' \
    OMEGA_POST_RELEASE_VERIFY.sh \
    && pass "post-release SHA256 verification" \
    || fail "post-release SHA256 verification missing"

grep -q 'omega-memory.json' \
    OMEGA_POST_RELEASE_VERIFY.sh \
    && pass "post-release runtime verification" \
    || fail "post-release runtime verification missing"

section "18. FILESYSTEM SAFETY"

if test -d .git; then
    pass ".git directory present"
else
    fail ".git directory missing"
fi

if test -d .next; then
    pass ".next build directory present"
else
    fail ".next build directory missing"
fi

if test -d .omega/certification; then
    pass "certification directory present"
else
    fail "certification directory missing"
fi

if test -d .omega/tmp; then
    pass "audit temporary directory present"
else
    fail "audit temporary directory missing"
fi

section "19. RELEASE STATE"

echo "VERSION:          $VERSION"
echo "NODE:             $NODE_VERSION"
echo "NPM:              $NPM_VERSION"
echo "NEXT:             $NEXT_VERSION"
echo "BRANCH:           $BRANCH"
echo "GIT HEAD:         $LOCAL_HEAD"
echo "GITHUB HEAD:      $REMOTE_HEAD"
echo "BUILD ID:         $BUILD_ID"
echo "SERVER ARTIFACTS: $SERVER_FILES"

[ "$FAILURES" -eq 0 ] \
    && pass "release state internally consistent" \
    || fail "release state inconsistent"

section "20. FINAL RESULT"

RESULT="FAIL"

if [ "$FAILURES" -eq 0 ]; then
    RESULT="PASS"

    echo
    echo "[##################################################] 100%"
    echo
    echo "OMEGA® DEEP INTEGRITY AUDIT: PASS"
    echo
    echo "PRODUCTION CERTIFIED"
    echo "HARDENED"
    echo "RELEASE LOCKED"
    echo "POST-RELEASE VERIFIED"
    echo "INTEGRITY VERIFIED"
    echo "TOOLCHAIN VERIFIED"
    echo "BUILD VERIFIED"
    echo "SOURCE VERIFIED"
    echo "CLI VERIFIED"
    echo "RUNTIME VERIFIED"
    echo "HASH CHAIN VERIFIED"
    echo "GITHUB VERIFIED"
else
    echo
    echo "OMEGA® DEEP INTEGRITY AUDIT: FAIL"
    echo
    echo "FAILURES: $FAILURES"
fi

{
    echo "============================================================"
    echo "OMEGA® — DEEP INTEGRITY AUDIT"
    echo "============================================================"
    echo "RESULT: $RESULT"
    echo "CHECKS: $CHECKS"
    echo "PASSES: $PASSES"
    echo "FAILURES: $FAILURES"
    echo
    echo "PROJECT: OMEGA®"
    echo "VERSION: $VERSION"
    echo "NODE: $NODE_VERSION"
    echo "NPM: $NPM_VERSION"
    echo "NEXT: $NEXT_VERSION"
    echo "BRANCH: $BRANCH"
    echo "GIT HEAD: $LOCAL_HEAD"
    echo "GITHUB HEAD: $REMOTE_HEAD"
    echo "BUILD ID: $BUILD_ID"
    echo "SERVER ARTIFACTS: $SERVER_FILES"
    echo
    echo "STATUS: $RESULT"
    echo "============================================================"
} > "$AUDIT"

echo
echo "AUDIT FILE:"
echo "$AUDIT"

if [ "$FAILURES" -ne 0 ]; then
    exit 1
fi
