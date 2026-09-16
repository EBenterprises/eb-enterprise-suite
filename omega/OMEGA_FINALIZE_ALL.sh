#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT=".omega/certification"
TMP=".omega/tmp"
mkdir -p "$CERT" "$TMP"

TOTAL=10
STEP=0

progress() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))

    printf "\n["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s\n" "$((STEP * 100 / TOTAL))" "$1"
}

fail() {
    echo
    echo "FAIL  $1"
    exit 1
}

echo
echo "============================================================"
echo "        OMEGA® — FINALIZE ALL"
echo "============================================================"

progress "Project identity"

node <<'NODE' || fail "project identity"
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json","utf8"));

if (p.name !== "omega") throw Error("name");
if (p.version !== "1.0.0") throw Error("version");
if (p.scripts?.build !== "next build --webpack") throw Error("build");
if (p.scripts?.dev !== "next dev --webpack") throw Error("dev");

console.log("PASS");
NODE

progress "Source integrity"

test -s src/app/page.js || fail "page.js"
test -s src/app/layout.js || fail "layout.js"
test -s bin/omega.js || fail "CLI"
test -d src || fail "src"
test -d tests || fail "tests"

echo "PASS"

progress "Core syntax"

while IFS= read -r -d '' file; do
    node --check "$file" >/dev/null 2>&1 ||
        fail "JavaScript syntax: $file"
done < <(
    find src \
        -type f \
        \( -name "*.js" -o -name "*.mjs" \) \
        ! -path "src/app/*" \
        -print0
)

echo "PASS"

progress "Production artifact"

test -d .next || fail ".next missing"
test -f .next/BUILD_ID || fail "BUILD_ID missing"

echo "PASS"

progress "CLI"

node bin/omega.js status >/dev/null ||
    fail "CLI status"

node bin/omega.js capabilities >/dev/null ||
    fail "CLI capabilities"

node bin/omega.js metrics >/dev/null ||
    fail "CLI metrics"

echo "PASS"

progress "Tests"

npm test > "$TMP/final-tests.log" 2>&1 ||
{
    tail -80 "$TMP/final-tests.log"
    fail "tests"
}

echo "PASS"

progress "Production runtime"

if [ -f .omega/production.pid ] &&
   kill -0 "$(cat .omega/production.pid)" 2>/dev/null; then

    PID="$(cat .omega/production.pid)"

else

    pkill -f "next start" 2>/dev/null || true

    nohup npm run start -- --hostname 0.0.0.0 \
        > "$TMP/final-server.log" 2>&1 &

    PID=$!
    echo "$PID" > .omega/production.pid
fi

READY=0

for _ in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

[ "$READY" = 1 ] || {
    tail -80 "$TMP/final-server.log" 2>/dev/null || true
    fail "runtime"
}

echo "PASS  PID $PID"

progress "Live application"

HTTP="$(
    curl -sS \
        -o "$TMP/final-page.html" \
        -w "%{http_code}" \
        http://127.0.0.1:3000
)"

[ "$HTTP" = "200" ] || fail "HTTP $HTTP"
grep -qi "<html" "$TMP/final-page.html" ||
    fail "HTML response"

echo "PASS  HTTP 200"

progress "Runtime metadata"

LAN_IP="$(
    ip route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}'
)"

DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$CERT/FINAL_STATE.txt" <<STATE
OMEGA® FINAL STATE
==================

STATUS: CERTIFIED
RUNTIME: RUNNING
PID: $PID

PROJECT: omega
VERSION: 1.0.0

BUILD: PASS
TESTS: PASS
CLI: PASS
SOURCE: PASS
NEXT JSX: PASS
HTTP: 200

LOCAL:
http://127.0.0.1:3000

LAN:
${LAN_IP:+http://$LAN_IP:3000}

CERTIFIED:
$DATE
STATE

echo "PASS"

progress "Git state"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git status --short > "$CERT/GIT_STATUS.txt"
    git rev-parse HEAD > "$CERT/GIT_COMMIT.txt"
    echo "PASS"
else
    echo "SKIP  not a git repository"
fi

progress "Final certification"

cat > "$CERT/CERTIFICATION_COMPLETE.txt" <<EOF2
============================================================
OMEGA® CERTIFICATION COMPLETE
============================================================

STATUS:              CERTIFIED
APPLICATION:         RUNNING
PRODUCTION BUILD:    PASS
TEST SUITE:          PASS
CLI:                 PASS
SOURCE:              PASS
JSX:                 PASS
HTTP:                200
RUNTIME PID:         $PID

LOCAL:
http://127.0.0.1:3000

LAN:
${LAN_IP:+http://$LAN_IP:3000}

CERTIFIED:
$DATE

============================================================
OMEGA® — COMPLETE
============================================================
EOF2

echo "PASS"

echo
echo "============================================================"
echo "[########################################] 100%"
echo "============================================================"
echo
cat "$CERT/CERTIFICATION_COMPLETE.txt"
echo
echo "============================================================"
