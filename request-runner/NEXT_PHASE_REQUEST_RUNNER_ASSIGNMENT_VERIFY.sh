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
echo " REQUEST RUNNER® — REQUEST/RUNNER ASSIGNMENT VERIFICATION"
echo " READ-ONLY / ISOLATED TEST DATA"
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

if [ -f apps/request-runner/requests.js ]; then
    if node --check apps/request-runner/requests.js; then
        ok "Request® module syntax valid"
    else
        bad "Request® module syntax failed"
    fi
else
    bad "Request® module missing"
fi

echo
echo "[3] RUNNER MODULE"
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
echo "[4] REQUEST/RUNNER ISOLATED LIFECYCLE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners) {
    throw new Error("Runner registry unavailable");
}

const runners = app.runners;

const runnerId = "__assignment_runner__";
const requestId = "__assignment_request__";

runners.register({
    id: runnerId,
    name: "Assignment Verification Runner®",
    status: "available"
});

let runner = runners.get(runnerId);

if (!runner) {
    throw new Error("Runner registration failed");
}

if (runner.status !== "available") {
    throw new Error("Runner is not initially available");
}

if (runners.countAvailable() !== 1) {
    throw new Error("Available Runner® count failed");
}

/*
 * Assignment contract:
 * A request assignment makes the Runner® busy and records
 * the current Request® identifier.
 */
runners.setUnavailable(runnerId, requestId);

runner = runners.get(runnerId);

if (!runner) {
    throw new Error("Runner disappeared after assignment");
}

if (runner.status !== "busy") {
    throw new Error("Runner did not enter busy state");
}

if (runner.currentRequestId !== requestId) {
    throw new Error("Current Request® identifier was not recorded");
}

if (runners.countAvailable() !== 0) {
    throw new Error("Busy Runner® still counted as available");
}

/*
 * Completion/release.
 */
runners.setAvailable(runnerId);

runner = runners.get(runnerId);

if (!runner) {
    throw new Error("Runner disappeared after release");
}

if (runner.status !== "available") {
    throw new Error("Runner did not return to available state");
}

if (runner.currentRequestId !== null) {
    throw new Error("Request assignment was not cleared");
}

if (runners.countAvailable() !== 1) {
    throw new Error("Runner availability was not restored");
}

/*
 * Remove isolated test state.
 */
runners.remove(runnerId);

if (runners.get(runnerId) !== null) {
    throw new Error("Isolated Runner® test state was not removed");
}

console.log("✓ Request® ↔ Runner® assignment lifecycle verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[5] APPLICATION LOAD"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app || typeof app !== "object") {
    throw new Error("Application failed to load");
}

if (!app.runners) {
    throw new Error("Runner® export missing");
}

console.log("✓ Request Runner® application surface loads");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[6] LAN SERVER"
echo "--------------------------------------------------------------"

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

if [ -n "$LAN_IP" ]; then
    ok "LAN address: $LAN_IP"
else
    bad "LAN address unavailable"
fi

HTTP_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        http://127.0.0.1:3000/ 2>/dev/null
)"

if [ "$HTTP_CODE" = "200" ]; then
    ok "Request Runner® HTTP 200"
else
    bad "Request Runner® HTTP $HTTP_CODE"
fi

echo
echo "=============================================================="
echo " REQUEST/RUNNER ASSIGNMENT RESULT"
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
