#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"

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
echo "        OMEGA® — HARDENING FINALIZATION"
echo "============================================================"
echo

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fail "not a git repository"

BRANCH="$(git branch --show-current)"
[ "$BRANCH" = "master" ] || fail "not on master"

test -s "$CERT/OMEGA_CERTIFIED.txt" \
    || fail "certification missing"

test -s "$CERT/OMEGA_RELEASE_FINGERPRINT.txt" \
    || fail "release fingerprint missing"

test -s "$CERT/OMEGA_CERTIFICATION_SHA256.txt" \
    || fail "SHA256 certification missing"

pass "certification artifacts present"

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

METRICS_OUTPUT="$(node bin/omega.js metrics)"

printf '%s\n' "$METRICS_OUTPUT" | node -e '
let data = "";
process.stdin.on("data", c => data += c);
process.stdin.on("end", () => {
    const value = JSON.parse(data);
    if (
        value === null ||
        typeof value !== "object" ||
        Array.isArray(value)
    ) process.exit(1);
});
' || fail "metrics JSON"

pass "metrics JSON contract"

if ! npm test > .omega/tmp/final-hardening-tests.log 2>&1; then
    tail -160 .omega/tmp/final-hardening-tests.log
    fail "test suite"
fi

grep -Eq 'fail[[:space:]]+0' .omega/tmp/final-hardening-tests.log \
    || fail "fail count"

grep -Eq 'pass[[:space:]]+39' .omega/tmp/final-hardening-tests.log \
    || fail "39 passing tests"

pass "39/39 tests"

test -s .next/BUILD_ID || fail "BUILD_ID missing"
test -s .next/server/pages-manifest.json || fail "pages-manifest missing"
test -s .next/server/app/page.js || fail "server page missing"
test -s .next/server/app/_not-found/page.js.nft.json \
    || fail "_not-found NFT missing"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"
[ "$SERVER_FILES" -gt 0 ] || fail "server artifacts missing"

pass "production artifacts: $SERVER_FILES"

grep -q 'config.cache = false' next.config.mjs \
    || fail "webpack cache lock missing"

grep -q 'cpus: 1' next.config.mjs \
    || fail "single CPU lock missing"

grep -q '"build": "next build --webpack"' package.json \
    || fail "webpack build command missing"

pass "Termux build configuration locked"

git diff --check || fail "git diff check"

git add \
    OMEGA_POST_CERTIFICATION_HARDEN.sh \
    .omega/certification/OMEGA_RELEASE_FINGERPRINT.txt \
    .omega/certification/OMEGA_CERTIFICATION_SHA256.txt

if git diff --cached --quiet; then
    echo "No hardening changes staged."
else
    git commit -m "OMEGA: finalize post-certification hardening"
    pass "hardening commit created"
fi

git push -u origin master \
    || fail "GitHub push failed"

pass "master pushed to GitHub"

git fetch origin master >/dev/null 2>&1 \
    || fail "GitHub fetch failed"

LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/master)"

[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] \
    || fail "GitHub synchronization mismatch"

pass "GitHub HEAD synchronized"

echo
echo "============================================================"
echo "        OMEGA® — FINAL HARDENED RELEASE"
echo "============================================================"
echo
echo "HEAD:"
echo "  $LOCAL_HEAD"
echo
echo "REMOTE:"
echo "  $REMOTE_HEAD"
echo
echo "SERVER ARTIFACTS:"
echo "  $SERVER_FILES"
echo
echo "TESTS:"
echo "  39/39 PASS"
echo
echo "RUNTIME STATE:"
echo "  data/omega-memory.json"
echo "  data/omega-state.json"
echo "  preserved as runtime state"
echo
echo "STATUS:"
echo "  OMEGA® PRODUCTION CERTIFIED + HARDENED"
echo
echo "============================================================"
