#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

clear

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

bad() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo "=============================================================="
echo " REQUEST RUNNER® — ASSIGNMENT PHASE RECHECK"
echo "=============================================================="

echo
echo "[1] PRODUCTION BASELINE"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed"
fi

echo
echo "[2] REQUEST MODULE"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/requests.js 2>/dev/null; then
    ok "Request® module valid"
else
    bad "Request® module failed"
fi

echo
echo "[3] RUNNER MODULE"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/runners.js 2>/dev/null; then
    ok "Runner® module valid"
else
    bad "Runner® module failed"
fi

echo
echo "[4] ASSIGNMENT LIFECYCLE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners) throw new Error("Runner® unavailable");

const runners = app.runners;

const runnerId = "__assignment_verify_runner__";
const requestId = "__assignment_verify_request__";

runners.register({
    id: runnerId,
    name: "Assignment Verification Runner®",
    status: "available"
});

if (runners.countAvailable() !== 1)
    throw new Error("Runner not available");

runners.setUnavailable(runnerId, requestId);

const busy = runners.get(runnerId);

if (!busy || busy.status !== "busy")
    throw new Error("Runner did not become busy");

if (busy.currentRequestId !== requestId)
    throw new Error("Request ID not attached");

runners.setAvailable(runnerId);

const available = runners.get(runnerId);

if (!available ||
    available.status !== "available" ||
    available.currentRequestId !== null) {
    throw new Error("Runner release failed");
}

runners.remove(runnerId);

console.log("✓ Request® ↔ Runner® lifecycle verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[5] LAN ADDRESS"
echo "--------------------------------------------------------------"

LAN_IP=""

LAN_IP="$(
    ifconfig 2>/dev/null |
    awk '
        /inet / {
            for (i=1;i<=NF;i++) {
                if ($i=="inet") {
                    ip=$(i+1)
                    if (ip !~ /^127\./) {
                        print ip
                        exit
                    }
                }
            }
        }
    '
)"

if [ -n "$LAN_IP" ]; then
    ok "LAN address: $LAN_IP"
else
    bad "LAN IPv4 unavailable"
fi

echo
echo "[6] LOCAL HTTP"
echo "--------------------------------------------------------------"

HTTP_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        http://127.0.0.1:3000/ 2>/dev/null
)"

if [ "$HTTP_CODE" = "200" ]; then
    ok "Local HTTP 200"
else
    bad "Local HTTP $HTTP_CODE"
fi

echo
echo "[7] LAN HTTP"
echo "--------------------------------------------------------------"

if [ -n "$LAN_IP" ]; then
    LAN_CODE="$(
        curl -sS \
            -o /dev/null \
            -w '%{http_code}' \
            --max-time 5 \
            "http://$LAN_IP:3000/" 2>/dev/null
    )"

    if [ "$LAN_CODE" = "200" ]; then
        ok "LAN HTTP 200"
    else
        bad "LAN HTTP $LAN_CODE"
    fi
else
    bad "LAN HTTP could not be tested"
fi

echo
echo "=============================================================="
echo " ASSIGNMENT PHASE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST/RUNNER ASSIGNMENT VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
