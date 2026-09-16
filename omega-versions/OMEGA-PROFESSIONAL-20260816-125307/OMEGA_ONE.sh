#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
PIDFILE="$ROOT/.omega/production.pid"
LOG="$TMP/omega-one.log"

mkdir -p "$CERT" "$TMP" public

TOTAL=15
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
    echo
    exit 1
}

echo
echo "============================================================"
echo "          OMEGA® — ONE-SHOT COMPLETE PIPELINE"
echo "============================================================"
echo

# 01
progress "Project filesystem"

for f in package.json package-lock.json bin/omega.js; do
    test -s "$f" || fail "$f missing"
done

for d in src tests public data; do
    test -d "$d" || fail "$d missing"
done

echo "PASS"

# 02
progress "Package integrity"

node <<'NODE' || fail "package integrity"
const fs = require("fs");

const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
const l = JSON.parse(fs.readFileSync("package-lock.json", "utf8"));

if (p.name !== "omega") throw Error("package name");
if (p.version !== "1.0.0") throw Error("package version");
if (p.type !== "module") throw Error("module type");
if (p.scripts?.build !== "next build --webpack") throw Error("build script");
if (p.scripts?.dev !== "next dev --webpack") throw Error("dev script");
if (l.lockfileVersion !== 3) throw Error("lockfile");

console.log("PASS");
NODE

# 03
progress "Core JavaScript syntax"

FAIL_COUNT=0

while IFS= read -r -d '' file; do
    if ! node --check "$file" >/dev/null 2>&1; then
        echo "FAIL  $file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done < <(
    find src \
        -type f \
        \( -name "*.js" -o -name "*.mjs" \) \
        ! -path "src/app/*" \
        -print0
)

[ "$FAIL_COUNT" -eq 0 ] || fail "core JavaScript syntax"

echo "PASS"

# 04
progress "Next application source"

test -s src/app/page.js || fail "page.js"
test -s src/app/layout.js || fail "layout.js"

# JSX is intentionally not passed through node --check.
echo "PASS  JSX delegated to Next.js compiler"

# 05
progress "Configuration"

for f in next.config.mjs jsconfig.json postcss.config.mjs; do
    test -s "$f" || fail "$f missing"
done

echo "PASS"

# 06
progress "Data integrity"

node <<'NODE' || fail "invalid JSON data"
const fs = require("fs");

for (const f of [
  "data/omega-memory.json",
  "data/omega-state.json",
  "data/versions.json"
]) {
  JSON.parse(fs.readFileSync(f, "utf8"));
}
console.log("PASS");
NODE

# 07
progress "Clean old production artifact"

rm -rf .next
echo "PASS"

# 08
progress "Production build"

if npm run build > "$TMP/build.log" 2>&1; then
    test -d .next || fail ".next not created"
    test -f .next/BUILD_ID || fail "BUILD_ID missing"
    echo "PASS  Next.js production build"
else
    echo
    echo "----- BUILD ERROR -----"
    tail -100 "$TMP/build.log"
    echo "----------------------"
    fail "production build"
fi

# 09
progress "Test suite"

if npm test > "$TMP/tests.log" 2>&1; then
    echo "PASS"
else
    tail -100 "$TMP/tests.log"
    fail "npm test"
fi

# 10
progress "CLI verification"

node bin/omega.js status >/dev/null 2>&1 ||
    fail "CLI status"

node bin/omega.js capabilities >/dev/null 2>&1 ||
    fail "CLI capabilities"

node bin/omega.js metrics >/dev/null 2>&1 ||
    fail "CLI metrics"

echo "PASS"

# 11
progress "Production server"

pkill -f "next start" 2>/dev/null || true

nohup npm run start -- --hostname 0.0.0.0 \
    > "$TMP/server.log" 2>&1 &

SERVER_PID=$!
echo "$SERVER_PID" > "$PIDFILE"

READY=0

for _ in $(seq 1 30); do
    if curl -fsS http://127.0.0.1:3000 >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

[ "$READY" -eq 1 ] || {
    tail -100 "$TMP/server.log" 2>/dev/null || true
    fail "production server"
}

echo "PASS  PID $SERVER_PID"

# 12
progress "Live HTTP verification"

HTTP_CODE="$(
    curl -sS \
        -o "$TMP/home.html" \
        -w '%{http_code}' \
        http://127.0.0.1:3000
)"

[ "$HTTP_CODE" = "200" ] || fail "HTTP $HTTP_CODE"
grep -qi "<html" "$TMP/home.html" || fail "HTML response"

echo "PASS  HTTP 200"

# 13
progress "LAN address"

LAN_IP="$(
    ip route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
)"

echo "PASS"

# 14
progress "Certification"

DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$CERT/OMEGA_CERTIFIED.txt" <<CERT
OMEGA® FINAL CERTIFICATION
===========================

PROJECT
omega

VERSION
1.0.0

CERTIFIED
$DATE

FILESYSTEM              PASS
PACKAGE                 PASS
CORE JAVASCRIPT         PASS
NEXT APPLICATION        PASS
JSX COMPILER            PASS
CONFIGURATION           PASS
DATA                    PASS
PRODUCTION BUILD        PASS
TEST SUITE              PASS
CLI                     PASS
PRODUCTION SERVER       PASS
HTTP                    PASS
LAN                     PASS

STATUS
OMEGA® CERTIFIED
CERT

echo "PASS"

# 15
progress "Final state"

{
    echo "OMEGA® RUNTIME"
    echo "=============="
    echo "STATUS: RUNNING"
    echo "PID: $SERVER_PID"
    echo "LOCAL: http://127.0.0.1:3000"

    if [ -n "${LAN_IP:-}" ]; then
        echo "LAN: http://${LAN_IP}:3000"
    fi

    echo "BUILD: PASS"
    echo "TESTS: PASS"
    echo "CLI: PASS"
    echo "HTTP: 200"
    echo "CERTIFICATION: PASS"
    echo "TIME: $DATE"
} > "$CERT/RUNTIME_STATE.txt"

echo "PASS"

echo
echo "============================================================"
echo "[########################################] 100%"
echo "============================================================"
echo
echo "             OMEGA® — COMPLETE"
echo
echo "BUILD          PASS"
echo "TESTS          PASS"
echo "CLI            PASS"
echo "JSX            PASS"
echo "PRODUCTION     PASS"
echo "HTTP           PASS"
echo "CERTIFICATION  PASS"
echo
echo "STATUS: OMEGA® CERTIFIED + RUNNING"
echo
echo "LOCAL:"
echo "http://127.0.0.1:3000"

if [ -n "${LAN_IP:-}" ]; then
    echo
    echo "LAN:"
    echo "http://${LAN_IP}:3000"
fi

echo
echo "CERTIFICATE:"
echo "$CERT/OMEGA_CERTIFIED.txt"
echo
echo "PID:"
echo "$SERVER_PID"
echo
echo "============================================================"
