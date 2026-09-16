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
echo " REQUEST RUNNER® — DISPATCH® VERIFICATION"
echo " ISOLATED TEST DATA / PRESERVE GREEN BASELINE"
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
echo "[2] DISPATCH MODULE"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/dispatch-runner.js; then
    ok "Dispatch® module syntax valid"
else
    bad "Dispatch® module syntax failed"
fi

echo
echo "[3] DISPATCH LIFECYCLE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners)
    throw new Error("Runner® registry unavailable");

if (!app.dispatchRunner)
    throw new Error("Dispatch® service unavailable");

const runners = app.runners;
const dispatch = app.dispatchRunner;

const runnerA = "__dispatch_runner_a__";
const runnerB = "__dispatch_runner_b__";
const requestA = "__dispatch_request_a__";
const requestB = "__dispatch_request_b__";

runners.register({
    id: runnerA,
    name: "Dispatch Runner A®",
    status: "available",
    capabilities: ["standard"]
});

runners.register({
    id: runnerB,
    name: "Dispatch Runner B®",
    status: "available",
    capabilities: ["priority", "standard"]
});

const selected = dispatch.select({
    capabilities: ["priority"]
});

if (!selected)
    throw new Error("No Runner® selected");

if (selected.id !== runnerB)
    throw new Error("Capability-aware selection failed");

const first = dispatch.dispatch(requestA, {
    capabilities: ["priority"]
});

if (first.runnerId !== runnerB)
    throw new Error("Dispatch selected incorrect Runner®");

if (first.status !== "dispatched")
    throw new Error("Dispatch status invalid");

if (runners.get(runnerB).status !== "busy")
    throw new Error("Dispatched Runner® not busy");

const second = dispatch.dispatch(requestB, {
    capabilities: ["standard"]
});

if (second.runnerId !== runnerA)
    throw new Error("Second dispatch did not select remaining Runner®");

if (runners.available().length !== 0)
    throw new Error("Busy Runners® incorrectly remain available");

dispatch.release(runnerB);

if (runners.get(runnerB).status !== "available")
    throw new Error("Runner® release failed");

if (runners.get(runnerB).currentRequestId !== null)
    throw new Error("Released Request® was not cleared");

dispatch.release(runnerA);

if (runners.get(runnerA).status !== "available")
    throw new Error("Second Runner® release failed");

runners.remove(runnerA);
runners.remove(runnerB);

console.log("✓ Dispatch® selection / assignment / release lifecycle verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[4] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners)
    throw new Error("Runner® export missing");

if (!app.dispatchRunner)
    throw new Error("Dispatch® export missing");

console.log("✓ Runner® + Dispatch® application surface loaded");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
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
    ok "Request Runner® HTTP 200"
else
    bad "Request Runner® HTTP $HTTP_CODE"
fi

echo
echo "=============================================================="
echo " DISPATCH® PHASE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "DISPATCH® VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
