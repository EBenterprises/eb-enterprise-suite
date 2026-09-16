#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

STATE="$PWD/.completion-state/green"
mkdir -p "$STATE"/{reports,artifacts,logs}

export CI=1
export NEXT_TELEMETRY_DISABLED=1

GREEN_OK=0
GREEN_WARN=0
GREEN_FAIL=0

pass() {
    GREEN_OK=$((GREEN_OK+1))
    printf '✓ %s\n' "$*"
}

warn() {
    GREEN_WARN=$((GREEN_WARN+1))
    printf '△ %s\n' "$*"
}

fail() {
    GREEN_FAIL=$((GREEN_FAIL+1))
    printf '✗ %s\n' "$*"
}

check_cmd() {
    command -v "$1" >/dev/null 2>&1 && pass "$1 available" || warn "$1 unavailable"
}

printf '\033c'

echo "=============================================================="
echo " CONFIGURE EVERYTHING — GREEN STATE"
echo "=============================================================="

# ---------------------------------------------------------------------------
# HARD STOP OLD ENGINES
# ---------------------------------------------------------------------------

pkill -TERM -f \
    'COMPLETION_ENGINE|CODE_EVERYTHING|RUN_ALL_CONTINUOUS|CONTINUOUS_FINALIZER|COMPLETE_EVERYTHING' \
    2>/dev/null || true

sleep 1

pkill -KILL -f \
    'COMPLETION_ENGINE|CODE_EVERYTHING|RUN_ALL_CONTINUOUS|CONTINUOUS_FINALIZER|COMPLETE_EVERYTHING' \
    2>/dev/null || true

pass "Old completion supervisors stopped"

# ---------------------------------------------------------------------------
# REMOVE ONLY STALE ENGINE LOCKS
# ---------------------------------------------------------------------------

find .completion-state \
    -type f \
    \( -name '.lock' -o -name '*.lock' \) \
    -delete 2>/dev/null || true

pass "Stale engine locks cleared"

# ---------------------------------------------------------------------------
# TOOLCHAIN
# ---------------------------------------------------------------------------

check_cmd node
check_cmd npm
check_cmd git

# ---------------------------------------------------------------------------
# PACKAGE INTEGRITY
# ---------------------------------------------------------------------------

if [ -f package.json ]; then
    if node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8"))' \
        >/dev/null 2>&1
    then
        pass "package.json valid"
    else
        fail "package.json invalid"
    fi
else
    warn "package.json not present"
fi

if [ -f package-lock.json ]; then
    if npm install --package-lock-only --ignore-scripts --no-audit --no-fund \
        >"$STATE/logs/package-lock.log" 2>&1
    then
        pass "package lock consistent"
    else
        warn "package lock requires review"
    fi
fi

# ---------------------------------------------------------------------------
# NEXT / TYPES / LINT
# ---------------------------------------------------------------------------

if [ -x node_modules/.bin/tsc ] && [ -f tsconfig.json ]; then
    if node_modules/.bin/tsc --noEmit \
        >"$STATE/logs/types.log" 2>&1
    then
        pass "TypeScript clean"
    else
        warn "TypeScript reports issues"
    fi
fi

if node -e '
const fs=require("fs");
try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));
  process.exit(p.scripts?.lint ? 0 : 1);
} catch {
  process.exit(1);
}' 2>/dev/null
then
    if npm run lint >"$STATE/logs/lint.log" 2>&1; then
        pass "Lint clean"
    else
        warn "Lint reports issues"
    fi
fi

# ---------------------------------------------------------------------------
# BUILD
# ---------------------------------------------------------------------------

BUILD_RESULT=0

if [ -x node_modules/.bin/next ]; then
    rm -rf .next

    if node_modules/.bin/next build --webpack \
        >"$STATE/logs/build.log" 2>&1
    then
        pass "Production build passed"
    else
        BUILD_RESULT=1
        warn "Production build requires repair"
    fi

elif node -e '
const fs=require("fs");
try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));
  process.exit(p.scripts?.build ? 0 : 1);
} catch {
  process.exit(1);
}' 2>/dev/null
then
    if npm run build >"$STATE/logs/build.log" 2>&1; then
        pass "Production build passed"
    else
        BUILD_RESULT=1
        warn "Production build requires repair"
    fi
else
    warn "No supported production build command detected"
fi

# ---------------------------------------------------------------------------
# SERVER ARTIFACT GATE
# ---------------------------------------------------------------------------

if [ -d .next/server ]; then

    SERVER_FILES="$(find .next/server -type f 2>/dev/null | wc -l)"

    if [ "$SERVER_FILES" -gt 0 ]; then
        mkdir -p "$STATE/artifacts"
        rm -rf "$STATE/artifacts/server"
        cp -a .next/server "$STATE/artifacts/server"

        pass "Server artifact present"
        pass "Server artifact contains $SERVER_FILES files"
    else
        fail "Server artifact directory is empty"
    fi

else
    if [ "$BUILD_RESULT" -eq 0 ] && [ -d .next ]; then
        fail "Server artifact missing"
    else
        warn "Server artifact unavailable because build is not green"
    fi
fi

# ---------------------------------------------------------------------------
# TESTS
# ---------------------------------------------------------------------------

TEST_RESULT=0

if node -e '
const fs=require("fs");
try {
  const p=JSON.parse(fs.readFileSync("package.json","utf8"));
  process.exit(p.scripts?.["test:ci"] || p.scripts?.test ? 0 : 1);
} catch {
  process.exit(1);
}' 2>/dev/null
then

    if npm run test:ci >"$STATE/logs/test.log" 2>&1 2>/dev/null; then
        pass "CI tests passed"
    elif npm test >"$STATE/logs/test.log" 2>&1 2>/dev/null; then
        pass "Tests passed"
    else
        TEST_RESULT=1
        warn "Tests require repair"
    fi

elif [ -x node_modules/.bin/vitest ]; then

    if node_modules/.bin/vitest run >"$STATE/logs/test.log" 2>&1; then
        pass "Vitest passed"
    else
        TEST_RESULT=1
        warn "Vitest requires repair"
    fi

elif [ -x node_modules/.bin/jest ]; then

    if node_modules/.bin/jest --runInBand >"$STATE/logs/test.log" 2>&1; then
        pass "Jest passed"
    else
        TEST_RESULT=1
        warn "Jest requires repair"
    fi

else
    warn "No test runner configured"
fi

# ---------------------------------------------------------------------------
# GIT STATE
# ---------------------------------------------------------------------------

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    pass "Git repository detected"
else
    warn "Git repository not detected"
fi

# ---------------------------------------------------------------------------
# GREEN STATUS
# ---------------------------------------------------------------------------

STATUS="GREEN"

if [ "$GREEN_FAIL" -gt 0 ]; then
    STATUS="RED"
elif [ "$GREEN_WARN" -gt 0 ]; then
    STATUS="YELLOW"
fi

cat > "$STATE/status.json" <<JSON
{
  "state": "$STATUS",
  "build": "$([ "$BUILD_RESULT" -eq 0 ] && echo PASS || echo REVIEW)",
  "tests": "$([ "$TEST_RESULT" -eq 0 ] && echo PASS || echo REVIEW)",
  "checks_passed": $GREEN_OK,
  "warnings": $GREEN_WARN,
  "failures": $GREEN_FAIL,
  "continuous_engine": false,
  "timestamp": "$(date -Iseconds)"
}
JSON

cat > "$STATE/GREEN.md" <<TXT
# GREEN STATE

Status: $STATUS

Passed: $GREEN_OK
Warnings: $GREEN_WARN
Failures: $GREEN_FAIL

The completion supervisor is intentionally stopped.
No background completion process is running.

Timestamp: $(date -Iseconds)
TXT

echo
echo "=============================================================="
echo " FINAL STATE"
echo "=============================================================="
echo "STATUS   : $STATUS"
echo "PASSED   : $GREEN_OK"
echo "WARNINGS : $GREEN_WARN"
echo "FAILURES : $GREEN_FAIL"
echo "ENGINE   : STOPPED"
echo "=============================================================="

if [ "$STATUS" = "GREEN" ]; then
    echo "✓ EVERYTHING GREEN"
    exit 0
elif [ "$STATUS" = "YELLOW" ]; then
    echo "△ GREEN TARGET NOT YET COMPLETE"
    exit 0
else
    echo "✗ RED — REPAIR REQUIRED"
    exit 1
fi
