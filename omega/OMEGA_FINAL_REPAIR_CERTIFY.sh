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
echo "        OMEGA® — FINAL REPAIR + CERTIFICATION"
echo "============================================================"
echo
echo "ROOT: $ROOT"
echo "DATE: $(date)"
echo

# ============================================================
# 1. BASELINE
# ============================================================

echo "=== 1. BASELINE ==="

test -f package.json || fail "package.json missing"
test -f package-lock.json || fail "package-lock.json missing"
test -f bin/omega.js || fail "bin/omega.js missing"
test -d src || fail "src missing"
test -d tests || fail "tests missing"

pass "project structure"

# ============================================================
# 2. NEXT / TERMUX BUILD STABILITY
# ============================================================

echo
echo "=== 2. TERMUX BUILD STABILITY ==="

test -f next.config.mjs || fail "next.config.mjs missing"

grep -q 'config.cache = false' next.config.mjs \
    || fail "webpack filesystem-cache fix missing"

grep -q 'cpus: 1' next.config.mjs \
    || fail "single-CPU configuration missing"

pass "webpack filesystem cache disabled"
pass "single CPU configured"

# ============================================================
# 3. REPAIR CLI
# ============================================================

echo
echo "=== 3. CLI CONTRACT ==="

cat > bin/omega.js <<'CLI'
#!/usr/bin/env node

import {
  execute,
  capabilities,
  health,
  metrics
} from "../src/core/omega.js"

const [command, ...args] = process.argv.slice(2)

const input = {
  prompt: args.join(" "),
  goal: args.join(" ")
}

const main = async () => {
  if (command === "status") {
    console.log(JSON.stringify(health(), null, 2))
    return
  }

  if (command === "capabilities" || command === "list") {
    console.log(JSON.stringify(capabilities(), null, 2))
    return
  }

  if (command === "metrics") {
    console.log(JSON.stringify(metrics.snapshot(), null, 2))
    return
  }

  if (command === "help") {
    console.log("OMEGA®")
    console.log("")
    console.log("Commands:")
    console.log("  status")
    console.log("  capabilities")
    console.log("  metrics")
    console.log("  invent <goal>")
    console.log("  simulate <target>")
    console.log("  evolve <generation>")
    console.log("  release <version>")
    return
  }

  if (!command) {
    console.log("OMEGA®")
    console.log(
      "status | capabilities | metrics | invent | simulate | evolve | release"
    )
    return
  }

  const result = await execute(command, input)
  console.log(JSON.stringify(result, null, 2))
}

main().catch(error => {
  console.error(`[OMEGA ERROR] ${error.message}`)
  process.exitCode = 1
})
CLI

chmod +x bin/omega.js

node --check bin/omega.js \
    || fail "CLI syntax"

pass "CLI syntax"

# ============================================================
# 4. METRICS API
# ============================================================

echo
echo "=== 4. METRICS API ==="

node --input-type=module <<'NODE'
import { metrics } from "./src/core/omega.js"

if (!metrics) {
  throw new Error("metrics export missing")
}

if (typeof metrics.snapshot !== "function") {
  throw new Error("metrics.snapshot() missing")
}

const snapshot = metrics.snapshot()

if (
  snapshot === null ||
  typeof snapshot !== "object" ||
  Array.isArray(snapshot)
) {
  throw new Error("metrics.snapshot() must return an object")
}

console.log("metrics.snapshot():")
console.log(JSON.stringify(snapshot, null, 2))
NODE

pass "metrics API"

# ============================================================
# 5. CLI COMMAND VERIFICATION
# ============================================================

echo
echo "=== 5. CLI VERIFICATION ==="

node bin/omega.js status >/dev/null \
    || fail "CLI status"

pass "status"

node bin/omega.js capabilities >/dev/null \
    || fail "CLI capabilities"

pass "capabilities"

node bin/omega.js metrics >/dev/null \
    || fail "CLI metrics"

pass "metrics"

node bin/omega.js help >/dev/null \
    || fail "CLI help"

pass "help"

# Verify actual JSON output from metrics.
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
    ) {
        process.exit(1);
    }
});
' || fail "CLI metrics JSON"

pass "metrics JSON contract"

# ============================================================
# 6. SOURCE SYNTAX
# ============================================================

echo
echo "=== 6. SOURCE SYNTAX ==="

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
# 7. TEST SUITE
# ============================================================

echo
echo "=== 7. TEST SUITE ==="

if ! npm test > "$TMP/final-tests.log" 2>&1; then
    echo
    echo "TEST FAILURE:"
    tail -160 "$TMP/final-tests.log"
    fail "npm test"
fi

grep -Eq 'fail[[:space:]]+0' "$TMP/final-tests.log" \
    || fail "test suite did not report fail 0"

grep -Eq 'pass[[:space:]]+39' "$TMP/final-tests.log" \
    || fail "expected 39 passing tests"

pass "39/39 tests"

# ============================================================
# 8. CLEAN PRODUCTION BUILD
# ============================================================

echo
echo "=== 8. CLEAN PRODUCTION BUILD ==="
echo
echo "This may take several minutes on Termux/Android."
echo "Do not interrupt the process."
echo

rm -rf .next

BUILD_START="$(date +%s)"

if ! npm run build > "$TMP/final-production-build.log" 2>&1; then
    echo
    echo "BUILD FAILURE:"
    tail -200 "$TMP/final-production-build.log"
    fail "production build"
fi

BUILD_END="$(date +%s)"
BUILD_SECONDS=$((BUILD_END - BUILD_START))

pass "production build"
echo "BUILD TIME: ${BUILD_SECONDS}s"

# ============================================================
# 9. PRODUCTION ARTIFACTS
# ============================================================

echo
echo "=== 9. PRODUCTION ARTIFACTS ==="

test -s .next/BUILD_ID \
    || fail "BUILD_ID missing"

pass "BUILD_ID"

test -s .next/server/pages-manifest.json \
    || fail "pages-manifest missing"

pass "pages-manifest"

test -s .next/server/app/page.js \
    || fail "application server page missing"

pass "application server page"

test -s .next/server/app/_not-found/page.js.nft.json \
    || fail "_not-found nft missing"

pass "_not-found nft"

SERVER_FILES="$(find .next/server -type f | wc -l | tr -d ' ')"

[ "$SERVER_FILES" -gt 0 ] \
    || fail "no server artifacts"

echo "SERVER ARTIFACTS: $SERVER_FILES"
pass "production artifact tree"

# ============================================================
# 10. POST-BUILD CLI
# ============================================================

echo
echo "=== 10. POST-BUILD CLI ==="

node bin/omega.js status >/dev/null \
    || fail "post-build CLI status"

node bin/omega.js capabilities >/dev/null \
    || fail "post-build CLI capabilities"

node bin/omega.js metrics >/dev/null \
    || fail "post-build CLI metrics"

node bin/omega.js help >/dev/null \
    || fail "post-build CLI help"

pass "CLI remains operational after production build"

# ============================================================
# 11. CERTIFICATION
# ============================================================

echo
echo "=== 11. CERTIFICATION ==="

VERSION="$(node -p 'JSON.parse(require("fs").readFileSync("package.json","utf8")).version')"
NODE_VERSION="$(node --version)"
NPM_VERSION="$(npm --version)"
NEXT_VERSION="$(node -p 'require("next/package.json").version')"
HEAD="$(git rev-parse HEAD 2>/dev/null || echo "NOT-A-GIT-REPOSITORY")"

cat > "$CERT/OMEGA_CERTIFIED.txt" <<CERT
============================================================
OMEGA® FINAL CERTIFICATION
============================================================

PROJECT
OMEGA®

VERSION
$VERSION

CERTIFIED
$(date -u +"%Y-%m-%dT%H:%M:%SZ")

ENVIRONMENT
Termux / Android

NODE
$NODE_VERSION

NPM
$NPM_VERSION

NEXT
$NEXT_VERSION

BUILD SYSTEM
Next.js
Webpack
Single CPU
Filesystem cache disabled

SOURCE VALIDATION
Core JavaScript: PASS
Next.js JSX compilation: PASS

CLI CONTRACT
status: PASS
capabilities: PASS
metrics: PASS
help: PASS

TESTS
39/39 PASS
fail: 0

PRODUCTION BUILD
PASS

PRODUCTION ARTIFACTS
BUILD_ID: PASS
pages-manifest: PASS
application server page: PASS
_not-found NFT: PASS
server artifact count: $SERVER_FILES

BUILD TIME
${BUILD_SECONDS}s

GIT HEAD
$HEAD

STATUS
CERTIFIED

============================================================
OMEGA® — PRODUCTION CERTIFIED
============================================================
CERT

test -s "$CERT/OMEGA_CERTIFIED.txt" \
    || fail "certificate missing"

pass "certification written"

# ============================================================
# 12. GIT INTEGRITY
# ============================================================

echo
echo "=== 12. GIT INTEGRITY ==="

git status --short

git diff --check \
    || fail "whitespace errors"

pass "git diff check"

# ============================================================
# 13. COMMIT
# ============================================================

echo
echo "=== 13. COMMIT VERIFIED CHANGES ==="

git add \
    bin/omega.js \
    next.config.mjs \
    OMEGA_FINAL_REPAIR_CERTIFY.sh \
    .omega/certification/OMEGA_CERTIFIED.txt

if git diff --cached --quiet; then
    echo "No new tracked changes to commit."
else
    git commit -m "OMEGA: finalize production certification"
    pass "certification commit"
fi

# ============================================================
# 14. PUSH
# ============================================================

echo
echo "=== 14. GITHUB ==="

if git remote get-url origin >/dev/null 2>&1; then

    REMOTE="$(git remote get-url origin)"

    echo "REMOTE: $REMOTE"

    git branch -M master

    git push -u origin master

    pass "master pushed to GitHub"

else
    echo "WARNING: origin remote is not configured."
    echo "Local certification is complete."
fi

# ============================================================
# FINAL
# ============================================================

echo
echo "============================================================"
echo "          OMEGA® — FINAL PRODUCTION CERTIFIED"
echo "============================================================"
echo
echo "[########################################] 100%"
echo
echo "  PASS  PROJECT"
echo "  PASS  TERMUX BUILD STABILITY"
echo "  PASS  CLI"
echo "  PASS  METRICS CONTRACT"
echo "  PASS  SOURCE SYNTAX"
echo "  PASS  39/39 TESTS"
echo "  PASS  PRODUCTION BUILD"
echo "  PASS  PRODUCTION ARTIFACTS"
echo "  PASS  POST-BUILD CLI"
echo "  PASS  CERTIFICATION"
echo "  PASS  GIT INTEGRITY"
echo
echo "  OMEGA® STATUS: CERTIFIED"
echo
echo "CERTIFICATE:"
echo "  $CERT/OMEGA_CERTIFIED.txt"
echo
echo "BUILD LOG:"
echo "  $TMP/final-production-build.log"
echo
echo "TEST LOG:"
echo "  $TMP/final-tests.log"
echo
echo "============================================================"
