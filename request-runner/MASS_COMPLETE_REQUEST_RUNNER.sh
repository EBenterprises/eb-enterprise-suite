#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/request-runner"
cd "$ROOT" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
WORK="$ROOT/.mass-complete-$STAMP"
LOG="$WORK/run.log"
PORT="${REQUEST_RUNNER_PORT:-3100}"
PID=""

mkdir -p "$WORK"

cleanup() {
    if [ -n "$PID" ]; then
        kill "$PID" 2>/dev/null || true
        wait "$PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

pass() { echo "✓ $*" | tee -a "$LOG"; }
fail() {
    echo "✗ $*" | tee -a "$LOG"
    echo "=== REQUEST RUNNER® — MASS COMPLETION STOPPED ==="
    exit 1
}

echo "=== REQUEST RUNNER® — MASS COMPLETION ===" | tee "$LOG"

echo "[1] CORE"
npm run eb:doctor >/dev/null 2>&1 || fail "doctor"
npm run eb:test >/dev/null 2>&1 || fail "tests"
npm run eb:status >/dev/null 2>&1 || fail "status"
pass "Doctor"
pass "Tests"
pass "Status"

echo "[2] BUILD"
npm run build >"$WORK/build.log" 2>&1 || {
    tail -40 "$WORK/build.log"
    fail "production build"
}
pass "Production build"

echo "[3] SERVER"
PORT="$PORT" npm start >"$WORK/server.log" 2>&1 &
PID=$!

READY=0
for _ in $(seq 1 30); do
    if curl -fsS \
        --connect-timeout 1 \
        "http://127.0.0.1:$PORT/api/health" \
        >"$WORK/health.json" 2>/dev/null; then
        READY=1
        break
    fi
    sleep 1
done

[ "$READY" -eq 1 ] || {
    tail -40 "$WORK/server.log" 2>/dev/null
    fail "server startup"
}

pass "Production server :$PORT"

echo "[4] HEALTH"
node - "$WORK/health.json" <<'NODE' || fail "health contract"
const fs = require("fs");
const x = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (x.ok !== true || x.status !== "healthy") process.exit(1);
console.log("healthy");
console.log("persistence:", x.persistence || "unknown");
NODE
pass "Health contract"

echo "[5] API CONTRACTS"
for endpoint in \
    customers requests orders drivers locations scheduling \
    payments notifications operations administration
do
    code="$(curl -sS \
        --connect-timeout 3 \
        -o "$WORK/$endpoint.json" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT/api/$endpoint" || true)"

    case "$code" in
        2??|3??) pass "/api/$endpoint [$code]" ;;
        *) fail "/api/$endpoint [$code]" ;;
    esac
done

echo "[6] FRONTEND CONTRACTS"
for route in / /request /requests /orders /drivers /ops; do
    code="$(curl -sS \
        --connect-timeout 3 \
        -o "$WORK/page.html" \
        -w '%{http_code}' \
        "http://127.0.0.1:$PORT$route" || true)"

    case "$code" in
        2??|3??) pass "$route [$code]" ;;
        *) fail "$route [$code]" ;;
    esac
done

echo "[7] SOURCE INTEGRITY"
test -f package.json || fail "package.json missing"
test -f next.config.js || fail "next.config.js missing"
test -f server.js || fail "server.js missing"
test -f framework/index.js || fail "framework/index.js missing"
test -f app/page.js || fail "app/page.js missing"
test -f app/layout.js || fail "app/layout.js missing"
test -f framework/security/authorization.js || fail "authorization missing"
pass "Required source surface"

echo "[8] AUTHORIZATION"
node <<'NODE' || fail "authorization contract"
const Authorization = require("./framework/security/authorization");
if (typeof Authorization !== "function") process.exit(1);
const a = new Authorization();
a.grant("operations", "request.manage");
if (!a.allows("operations", "request.manage")) process.exit(1);
console.log("authorization contract passed");
NODE
pass "Authorization"

echo "[9] SERVER ERROR SCAN"
if grep -Eqi \
  '(^|[^a-z])(fatal|unhandled|uncaught exception)([^a-z]|$)' \
  "$WORK/server.log" 2>/dev/null; then
    tail -40 "$WORK/server.log"
    fail "fatal/unhandled server error"
fi
pass "No fatal/unhandled server errors"

echo "[10] GIT AVAILABILITY"
if command -v git >/dev/null 2>&1; then
    pass "Git available"
else
    echo "! Git unavailable — source remains local"
fi

echo "[11] FINAL TEST"
npm run eb:test >/dev/null 2>&1 || fail "final tests"
pass "Final tests"

echo
echo "=== REQUEST RUNNER® — MASS COMPLETION PASSED ==="
echo "Artifacts: $WORK"
echo "Status: GREEN"
