#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
PIDFILE="$ROOT/.omega/production.pid"
SERVER_LOG="$TMP/production-server.log"

mkdir -p "$CERT" "$TMP"

rm -f \
  "$CERT/OMEGA_CERTIFIED.txt" \
  "$CERT/RUNTIME_STATE.txt" \
  "$CERT/CERTIFICATION_HASH.txt"

TOTAL=14
STEP=0

progress() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))

    printf "\n["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s\n" \
        "$((STEP * 100 / TOTAL))" "$1"
}

fail() {
    echo
    echo "============================================================"
    echo "OMEGA® CERTIFICATION FAILED"
    echo "============================================================"
    echo
    echo "FAIL: $1"
    echo
    exit 1
}

cleanup_old_server() {
    if [ -f "$PIDFILE" ]; then
        OLD_PID="$(cat "$PIDFILE" 2>/dev/null || true)"

        if [ -n "${OLD_PID:-}" ] &&
           [[ "$OLD_PID" =~ ^[0-9]+$ ]] &&
           kill -0 "$OLD_PID" 2>/dev/null; then
            kill "$OLD_PID" 2>/dev/null || true
            sleep 1
        fi
    fi

    pkill -f "next start" 2>/dev/null || true
    rm -f "$PIDFILE"
}

echo
echo "============================================================"
echo "          OMEGA® — CERTIFICATION PIPELINE"
echo "============================================================"

# ============================================================
# 01 — FILESYSTEM
# ============================================================

progress "Verify project filesystem"

for f in \
    package.json \
    package-lock.json \
    bin/omega.js \
    src/app/page.js \
    src/app/layout.js \
    next.config.mjs \
    jsconfig.json \
    postcss.config.mjs
do
    test -s "$f" || fail "Missing required file: $f"
done

for d in src tests public data; do
    test -d "$d" || fail "Missing required directory: $d"
done

echo "PASS"

# ============================================================
# 02 — PACKAGE
# ============================================================

progress "Verify package configuration"

node <<'NODE' || fail "package configuration invalid"
const fs = require("fs");

const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
const l = JSON.parse(fs.readFileSync("package-lock.json", "utf8"));

if (p.name !== "omega")
    throw Error("package name");

if (p.version !== "1.0.0")
    throw Error("package version");

if (p.type !== "module")
    throw Error("module type");

if (p.scripts?.build !== "next build --webpack")
    throw Error("build script");

if (p.scripts?.dev !== "next dev --webpack")
    throw Error("dev script");

if (p.scripts?.start !== "next start")
    throw Error("start script must be next start");

if (l.lockfileVersion !== 3)
    throw Error("lockfile version");

console.log("PASS");
NODE

# ============================================================
# 03 — SOURCE
# ============================================================

progress "Verify JavaScript source"

FAIL_COUNT=0

while IFS= read -r -d '' file; do
    if ! node --check "$file" >/dev/null 2>&1; then
        echo "FAIL: $file"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done < <(
    find src \
        -type f \
        \( -name "*.js" -o -name "*.mjs" \) \
        ! -path "src/app/*" \
        -print0
)

[ "$FAIL_COUNT" -eq 0 ] ||
    fail "JavaScript syntax errors"

echo "PASS"

# ============================================================
# 04 — DATA
# ============================================================

progress "Verify data integrity"

node <<'NODE' || exit 1
const fs = require("fs");

for (const file of [
    "data/omega-memory.json",
    "data/omega-state.json",
    "data/versions.json"
]) {
    try {
        JSON.parse(fs.readFileSync(file, "utf8"));
    } catch (err) {
        console.error("INVALID:", file);
        throw err;
    }
}

console.log("PASS");
NODE

# ============================================================
# 05 — CLEAN BUILD
# ============================================================

progress "Clean production artifact"

rm -rf .next

echo "PASS"

# ============================================================
# 06 — PRODUCTION BUILD
# ============================================================

progress "Build production application"

if npm run build > "$TMP/build.log" 2>&1; then
    test -s .next/BUILD_ID ||
        fail "Next production BUILD_ID missing"

    echo "PASS"
else
    echo
    tail -120 "$TMP/build.log"
    fail "Next.js production build failed"
fi

# ============================================================
# 07 — TESTS
# ============================================================

progress "Run test suite"

if npm test > "$TMP/tests.log" 2>&1; then
    echo "PASS"
else
    echo
    tail -120 "$TMP/tests.log"
    fail "Test suite failed"
fi

# ============================================================
# 08 — CLI
# ============================================================

progress "Verify OMEGA CLI"

node bin/omega.js status >/dev/null 2>&1 ||
    fail "CLI status failed"

node bin/omega.js capabilities >/dev/null 2>&1 ||
    fail "CLI capabilities failed"

node bin/omega.js metrics >/dev/null 2>&1 ||
    fail "CLI metrics failed"

echo "PASS"

# ============================================================
# 09 — REAL PRODUCTION SERVER
# ============================================================

progress "Start real Next.js production server"

cleanup_old_server

: > "$SERVER_LOG"

nohup npm run start -- --hostname 0.0.0.0 --port 3000 \
    > "$SERVER_LOG" 2>&1 &

SERVER_PID=$!

echo "$SERVER_PID" > "$PIDFILE"

sleep 2

kill -0 "$SERVER_PID" 2>/dev/null ||
    fail "Next.js process exited immediately"

echo "PASS  PID $SERVER_PID"

# ============================================================
# 10 — SERVER STABILITY + HTTP
# ============================================================

progress "Verify live production runtime"

READY=0

for _ in $(seq 1 30); do

    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo
        cat "$SERVER_LOG" 2>/dev/null || true
        fail "Production server process died"
    fi

    if curl -fsS \
        --max-time 3 \
        http://127.0.0.1:3000 \
        > "$TMP/home.html" 2>/dev/null
    then
        READY=1
        break
    fi

    sleep 1
done

[ "$READY" -eq 1 ] ||
{
    echo
    cat "$SERVER_LOG" 2>/dev/null || true
    fail "Production server did not become ready"
}

HTTP_CODE="$(
    curl -sS \
        --max-time 5 \
        -o "$TMP/home.html" \
        -w '%{http_code}' \
        http://127.0.0.1:3000
)"

[ "$HTTP_CODE" = "200" ] ||
    fail "HTTP status was $HTTP_CODE"

grep -qi "<html" "$TMP/home.html" ||
    fail "Production response was not HTML"

kill -0 "$SERVER_PID" 2>/dev/null ||
    fail "Server died after HTTP verification"

echo "PASS  HTTP 200"
echo "PASS  HTML verified"
echo "PASS  process stable"

# ============================================================
# 11 — SECOND HTTP PROBE
# ============================================================

progress "Perform independent runtime probe"

sleep 2

kill -0 "$SERVER_PID" 2>/dev/null ||
    fail "Server failed stability probe"

SECOND_CODE="$(
    curl -sS \
        --max-time 5 \
        -o /dev/null \
        -w '%{http_code}' \
        http://127.0.0.1:3000
)"

[ "$SECOND_CODE" = "200" ] ||
    fail "Second HTTP probe returned $SECOND_CODE"

echo "PASS"

# ============================================================
# 12 — RUNTIME STATE
# ============================================================

progress "Record verified runtime state"

DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

LAN_IP="$(
    ip route get 1.1.1.1 2>/dev/null |
    awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
)"

cat > "$CERT/RUNTIME_STATE.txt" <<STATE
OMEGA® RUNTIME STATE
====================

STATUS: RUNNING

PID: $SERVER_PID

LOCAL:
http://127.0.0.1:3000

LAN:
${LAN_IP:+http://$LAN_IP:3000}

NEXT PRODUCTION SERVER: VERIFIED
PROCESS ALIVE: VERIFIED
HTTP STATUS: 200
HTML RESPONSE: VERIFIED
SECOND HTTP PROBE: 200
BUILD ARTIFACT: VERIFIED

TIMESTAMP:
$DATE
STATE

test -s "$CERT/RUNTIME_STATE.txt" ||
    fail "Runtime state was not created"

echo "PASS"

# ============================================================
# 13 — CERTIFICATION
# ============================================================

progress "Issue OMEGA® certification"

cat > "$CERT/OMEGA_CERTIFIED.txt" <<CERT
OMEGA® FINAL CERTIFICATION
===========================

PROJECT
omega

VERSION
1.0.0

CERTIFICATION TIME
$DATE

CERTIFICATION BASIS
-------------------

FILESYSTEM              PASS
PACKAGE                 PASS
SOURCE                  PASS
DATA                    PASS
PRODUCTION BUILD        PASS
TEST SUITE              PASS
CLI                     PASS
REAL NEXT SERVER        PASS
PROCESS STABILITY       PASS
HTTP 200                PASS
HTML RESPONSE           PASS
SECOND HTTP PROBE       PASS
RUNTIME STATE           PASS

PRODUCTION ENDPOINT
-------------------

http://127.0.0.1:3000

CERTIFICATION STATUS
--------------------

OMEGA® CERTIFIED

This certificate was generated only after
all required certification gates passed.
CERT

test -s "$CERT/OMEGA_CERTIFIED.txt" ||
    fail "Certification file was not created"

echo "PASS"

# ============================================================
# 14 — POST-CERTIFICATION AUDIT
# ============================================================

progress "Perform post-certification audit"

test -s "$CERT/OMEGA_CERTIFIED.txt" ||
    fail "Certificate missing"

test -s "$CERT/RUNTIME_STATE.txt" ||
    fail "Runtime state missing"

test -s ".next/BUILD_ID" ||
    fail "BUILD_ID missing"

kill -0 "$SERVER_PID" 2>/dev/null ||
    fail "Server stopped after certification"

FINAL_CODE="$(
    curl -sS \
        --max-time 5 \
        -o /dev/null \
        -w '%{http_code}' \
        http://127.0.0.1:3000
)"

[ "$FINAL_CODE" = "200" ] ||
    fail "Post-certification HTTP check failed: $FINAL_CODE"

CERT_HASH="$(
    sha256sum "$CERT/OMEGA_CERTIFIED.txt" |
    awk '{print $1}'
)"

RUNTIME_HASH="$(
    sha256sum "$CERT/RUNTIME_STATE.txt" |
    awk '{print $1}'
)"

BUILD_HASH="$(
    sha256sum ".next/BUILD_ID" |
    awk '{print $1}'
)"

cat > "$CERT/CERTIFICATION_HASH.txt" <<HASH
OMEGA® CERTIFICATION INTEGRITY RECORD
======================================

CERTIFICATE_SHA256
$CERT_HASH

RUNTIME_STATE_SHA256
$RUNTIME_HASH

BUILD_ID_SHA256
$BUILD_HASH

FINAL_HTTP_STATUS
$FINAL_CODE

FINAL_PROCESS
RUNNING

CERTIFICATION_TIME
$DATE
HASH

test -s "$CERT/CERTIFICATION_HASH.txt" ||
    fail "Integrity record missing"

echo "PASS"

echo
echo "============================================================"
echo "[########################################] 100%"
echo "============================================================"
echo
echo "              OMEGA® — CERTIFIED"
echo
echo "BUILD              PASS"
echo "TESTS              PASS"
echo "CLI                PASS"
echo "NEXT SERVER        PASS"
echo "PROCESS            PASS"
echo "HTTP               200"
echo "HTML               PASS"
echo "RUNTIME            PASS"
echo "CERTIFICATE        PASS"
echo "INTEGRITY RECORD   PASS"
echo
echo "STATUS:"
echo "OMEGA® CERTIFIED + RUNNING"
echo
echo "CERTIFICATE:"
echo "$CERT/OMEGA_CERTIFIED.txt"
echo
echo "RUNTIME:"
echo "$CERT/RUNTIME_STATE.txt"
echo
echo "INTEGRITY:"
echo "$CERT/CERTIFICATION_HASH.txt"
echo
echo "PID:"
echo "$SERVER_PID"
echo
echo "LOCAL:"
echo "http://127.0.0.1:3000"
echo
echo "============================================================"
