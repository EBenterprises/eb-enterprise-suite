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
echo " REQUEST RUNNER® — DISPATCH → STATE® INTEGRATION VERIFICATION"
echo " ISOLATED TEST DATA / PRESERVE GREEN BASELINE"
echo "=============================================================="

echo
echo "[1] PRODUCTION BASELINE"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo
echo "[2] REQUIRED MODULES"
echo "--------------------------------------------------------------"

for file in \
    apps/request-runner/requests.js \
    apps/request-runner/request-queue.js \
    apps/request-runner/dispatch.js \
    apps/request-runner/dispatch-state.js \
    apps/request-runner/runners.js \
    apps/request-runner/dispatch-runner.js
do
    if [ -f "$file" ] && node --check "$file" >/dev/null 2>&1; then
        ok "$file valid"
    else
        bad "$file missing or invalid"
    fi
done

echo
echo "[3] DISPATCH → STATE® INTEGRATION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");
const requests = require("./apps/request-runner/requests");
const queue = require("./apps/request-runner/request-queue");
const dispatch = require("./apps/request-runner/dispatch");
const state = require("./apps/request-runner/dispatch-state");
const runners = require("./apps/request-runner/runners");

const requestId = "__dispatch_state_integration__";
const runnerId = "__dispatch_state_integration_runner__";

function cleanup() {
    try { queue.remove(requestId); } catch (_) {}
    try { requests.remove(requestId); } catch (_) {}
    try { state.remove(requestId); } catch (_) {}
    try {
        if (typeof runners.remove === "function") {
            runners.remove(runnerId);
        }
    } catch (_) {}
}

cleanup();

requests.create({
    id: requestId,
    status: "created",
    priority: 100
});

requests.update(requestId, {
    status: "queued"
});

queue.enqueue({
    id: requestId,
    priority: 100
});

runners.register({
    id: runnerId,
    name: "Dispatch State Integration Runner®",
    status: "available"
});

const assignment = dispatch.assign({
    requestId,
    runnerId
});

if (!assignment) {
    throw new Error("Dispatch® assignment failed");
}

const dispatchState = state.get(requestId);

if (!dispatchState) {
    throw new Error(
        "Dispatch® assignment did not create Dispatch State®"
    );
}

if (dispatchState.requestId !== requestId) {
    throw new Error(
        "Dispatch State® Request identity mismatch"
    );
}

if (dispatchState.runnerId !== runnerId) {
    throw new Error(
        "Dispatch State® Runner identity mismatch"
    );
}

if (dispatchState.status !== "assigned") {
    throw new Error(
        `Expected assigned state, received: ${dispatchState.status}`
    );
}

console.log(
    "✓ Dispatch® created synchronized Dispatch State®"
);

cleanup();

if (state.get(requestId) !== null) {
    throw new Error("Dispatch State® test state leaked");
}

if (requests.get(requestId) !== null) {
    throw new Error("Request® test state leaked");
}

if (queue.get(requestId) !== null) {
    throw new Error("Queue® test state leaked");
}

console.log(
    "✓ Dispatch® integration test state cleared"
);
NODE
then
    ok "Dispatch® → Dispatch State® integration verified"
else
    bad "Dispatch® → Dispatch State® integration failed"
fi

echo
echo "[4] STATE TRANSITION AFTER DISPATCH"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const state = require("./apps/request-runner/dispatch-state");

const id = "__post_dispatch_transition__";

state.create(id, {
    status: "queued",
    runnerId: null
});

state.update(id, {
    status: "assigned",
    runnerId: "__transition_runner__"
});

let current = state.get(id);

if (
    !current ||
    current.status !== "assigned" ||
    current.runnerId !== "__transition_runner__"
) {
    throw new Error("Assigned Dispatch State® invalid");
}

state.update(id, {
    status: "in_progress"
});

current = state.get(id);

if (!current || current.status !== "in_progress") {
    throw new Error("In-progress Dispatch State® invalid");
}

state.update(id, {
    status: "completed"
});

current = state.get(id);

if (!current || current.status !== "completed") {
    throw new Error("Completed Dispatch State® invalid");
}

state.remove(id);

if (state.get(id) !== null) {
    throw new Error("Dispatch State® transition state leaked");
}

console.log(
    "✓ Dispatch State® post-assignment transitions verified"
);
NODE
then
    ok "Dispatch State® transition chain verified"
else
    bad "Dispatch State® transition chain failed"
fi

echo
echo "[5] INVALID STATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const state = require("./apps/request-runner/dispatch-state");

const id = "__dispatch_invalid_state__";

state.create(id, {
    status: "queued"
});

let rejected = false;

try {
    state.update(id, {
        status: "not_a_real_state"
    });
} catch (_) {
    rejected = true;
}

state.remove(id);

if (!rejected) {
    throw new Error(
        "Invalid Dispatch State® was accepted"
    );
}

console.log(
    "✓ Invalid Dispatch State® rejected"
);
NODE
then
    ok "Invalid Dispatch State® protection verified"
else
    bad "Invalid Dispatch State® protection failed"
fi

echo
echo "[6] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app || typeof app !== "object") {
    throw new Error("Application failed to load");
}

for (const key of [
    "requestQueue",
    "dispatch",
    "dispatchState",
    "runners"
]) {
    if (!app[key]) {
        throw new Error(
            `Application surface missing: ${key}`
        );
    }
}

console.log(
    "✓ Request® + Queue® + Dispatch® + State® + Runner® surface intact"
);
NODE
then
    ok "Application surface remains intact"
else
    bad "Application surface failed"
fi

echo
echo "[7] LOCAL SERVER"
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
echo "[8] PRODUCTION BASELINE RECHECK"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed after verification"
fi

echo
echo "=============================================================="
echo " DISPATCH → STATE® INTEGRATION RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "DISPATCH → STATE® INTEGRATION VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — REPAIR REQUIRED"
    exit 1
fi

echo "=============================================================="
