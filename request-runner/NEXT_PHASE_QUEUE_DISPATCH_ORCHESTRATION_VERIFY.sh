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
echo " REQUEST RUNNER® — QUEUE → DISPATCH® ORCHESTRATION VERIFICATION"
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
echo "[2] REQUIRED PRODUCT SURFACES"
echo "--------------------------------------------------------------"

for f in \
    apps/request-runner/requests.js \
    apps/request-runner/runners.js \
    apps/request-runner/dispatch.js \
    apps/request-runner/dispatch-state.js \
    apps/request-runner/request-queue.js
do
    if [ -f "$f" ] && node --check "$f" >/dev/null 2>&1; then
        ok "$f valid"
    else
        bad "$f missing or invalid"
    fi
done

echo
echo "[3] ORCHESTRATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app || typeof app !== "object") {
    throw new Error("Application failed to load");
}

if (!app.runners) {
    throw new Error("Runner® surface missing");
}

const dispatch = app.dispatch;
const queue =
    app.requestQueue ||
    app.queue ||
    app.requestsQueue;

if (!dispatch) {
    throw new Error("Dispatch® surface missing");
}

if (!queue) {
    throw new Error("Request Queue® surface missing");
}

console.log("✓ Queue® + Dispatch® + Runner® surfaces loaded");
NODE
then
    ok "Product orchestration surfaces loaded"
else
    bad "Product orchestration surfaces unavailable"
fi

echo
echo "[4] QUEUE → RUNNER ASSIGNMENT"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

const runners = app.runners;
const dispatch = app.dispatch;
const queue =
    app.requestQueue ||
    app.queue ||
    app.requestsQueue;

if (!runners || !dispatch || !queue) {
    throw new Error("Required orchestration services unavailable");
}

const runnerId = "__orchestration_runner__";
const requestId = "__orchestration_request__";

try {
    /*
     * Register isolated Runner®.
     */
    runners.register({
        id: runnerId,
        name: "Orchestration Verification Runner®",
        status: "available"
    });

    /*
     * Locate a queue insertion method without changing
     * the production implementation.
     */
    const enqueue =
        queue.enqueue ||
        queue.add ||
        queue.push ||
        queue.submit;

    if (typeof enqueue !== "function") {
        throw new Error("Queue enqueue operation unavailable");
    }

    /*
     * Add isolated Request®.
     */
    const request = {
        id: requestId,
        status: "queued",
        priority: 100
    };

    enqueue.call(queue, request);

    /*
     * Locate dispatch operation.
     */
    const assign =
        dispatch.assign ||
        dispatch.dispatch ||
        dispatch.assignNext ||
        dispatch.next;

    if (typeof assign !== "function") {
        throw new Error("Dispatch assignment operation unavailable");
    }

    /*
     * Execute the available dispatch operation.
     * Implementations may return the assignment or mutate
     * the Runner®/Request® state directly.
     */
    let result;

    try {
        result = assign.call(dispatch, {
            requestId,
            runnerId
        });
    } catch (firstError) {
        try {
            result = assign.call(dispatch, requestId, runnerId);
        } catch {
            throw firstError;
        }
    }

    const runner = runners.get(runnerId);

    if (!runner) {
        throw new Error("Verification Runner® disappeared");
    }

    /*
     * Accept either explicit assignment state or a returned
     * assignment object, while requiring a real relationship.
     */
    const assigned =
        runner.currentRequestId === requestId ||
        (result &&
         (
             result.requestId === requestId ||
             result.currentRequestId === requestId
         ));

    if (!assigned) {
        throw new Error("Queue → Runner® assignment was not established");
    }

    console.log("✓ Request Queue® → Dispatch® → Runner® assignment verified");

} finally {
    /*
     * Remove only isolated Runner® test state.
     */
    try {
        runners.remove(runnerId);
    } catch {}
}
NODE
then
    ok "Queue → Dispatch® → Runner® orchestration verified"
else
    bad "Queue → Dispatch® → Runner® orchestration failed"
fi

echo
echo "[5] NO CROSS-TEST CONTAMINATION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners) {
    throw new Error("Runner registry unavailable");
}

const runner = app.runners.get("__orchestration_runner__");

if (runner !== null) {
    throw new Error("Isolated Runner® state leaked");
}

console.log("✓ Isolated orchestration state cleared");
NODE
then
    ok "No orchestration test state leaked"
else
    bad "Orchestration test state detected"
fi

echo
echo "[6] LOCAL SERVER"
echo "--------------------------------------------------------------"

HTTP_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        http://127.0.0.1:3000/ 2>/dev/null || echo 000
)"

if [ "$HTTP_CODE" = "200" ]; then
    ok "Request Runner® HTTP 200"
else
    bad "Request Runner® HTTP $HTTP_CODE"
fi

echo
echo "=============================================================="
echo " QUEUE → DISPATCH® ORCHESTRATION RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "QUEUE → DISPATCH® → RUNNER® ORCHESTRATION VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
