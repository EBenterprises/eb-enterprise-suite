#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

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
echo " REQUEST RUNNER® — RUNNER PHASE VERIFICATION"
echo " READ-ONLY / PRESERVE GREEN BASELINE"
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
echo "[2] RUNNER MODULE"
echo "--------------------------------------------------------------"

if [ -f apps/request-runner/runners.js ]; then
    if node --check apps/request-runner/runners.js; then
        ok "Runner® module syntax valid"
    else
        bad "Runner® module syntax failed"
    fi
else
    bad "Runner® module missing"
fi

echo
echo "[3] APPLICATION EXPORT"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners) {
    throw new Error("Runner export missing");
}

const runners = app.runners;

runners.register({
    id: "__verification_runner__",
    name: "Verification Runner®",
    status: "available"
});

if (runners.countAvailable() !== 1) {
    throw new Error("Available state failed");
}

runners.setUnavailable(
    "__verification_runner__",
    "__verification_request__"
);

if (runners.countAvailable() !== 0) {
    throw new Error("Busy state failed");
}

const runner = runners.get("__verification_runner__");

if (!runner || runner.currentRequestId !== "__verification_request__") {
    throw new Error("Request assignment failed");
}

runners.setAvailable("__verification_runner__");

if (runners.countAvailable() !== 1) {
    throw new Error("Return-to-available failed");
}

runners.remove("__verification_runner__");

if (runners.get("__verification_runner__") !== null) {
    throw new Error("Runner cleanup failed");
}

console.log("✓ Runner® lifecycle verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[4] LAN SERVER"
echo "--------------------------------------------------------------"

LAN_IP=""

LAN_IP="$(
    ifconfig wlan0 2>/dev/null |
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

if [ -z "$LAN_IP" ]; then
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
fi

if [ -n "$LAN_IP" ]; then
    ok "LAN address: $LAN_IP"
else
    bad "LAN address unavailable"
fi

echo
echo "[5] LOCAL SERVER"
echo "--------------------------------------------------------------"

HTTP_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        http://127.0.0.1:3000/ 2>/dev/null
)"

if [ "$HTTP_CODE" = "200" ]; then
    ok "Request Runner® server HTTP 200"
else
    bad "Request Runner® server HTTP $HTTP_CODE"
fi

echo
echo "[6] LAN SERVER"
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
    bad "LAN HTTP skipped because address unavailable"
fi

echo
echo "=============================================================="
echo " RUNNER PHASE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "RUNNER PHASE VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
