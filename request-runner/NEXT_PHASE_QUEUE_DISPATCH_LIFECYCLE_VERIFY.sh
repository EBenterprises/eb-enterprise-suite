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
echo " REQUEST RUNNER® — QUEUE → DISPATCH® LIFECYCLE VERIFICATION"
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
echo "[3] QUEUE → DISPATCH® CONTRACT"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const requests = require("./apps/request-runner/requests");
const queue = require("./apps/request-runner/request-queue");
const dispatch = require("./apps/request-runner/dispatch");
const state = require("./apps/request-runner/dispatch-state");
const runners = require("./apps/request-runner/runners");

const requestId = "__queue_dispatch_lifecycle__";
const runnerId = "__queue_dispatch_runner__";

if (
    !requests ||
    typeof requests.create !== "function" ||
    typeof requests.get !== "function" ||
    typeof requests.update !== "function" ||
    typeof requests.remove !== "function"
) {
    throw new Error("Request® lifecycle surface unavailable");
}

if (
    !queue ||
    typeof queue.enqueue !== "function" ||
    typeof queue.get !== "function" ||
    typeof queue.remove !== "function"
) {
    throw new Error("Request Queue® surface unavailable");
}

if (!dispatch || typeof dispatch.assign !== "function") {
    throw new Error("Dispatch® assignment surface unavailable");
}

if (
    !state ||
    typeof state.create !== "function" ||
    typeof state.get !== "function" ||
    typeof state.update !== "function" ||
    typeof state.remove !== "function"
) {
    throw new Error("Dispatch State® surface unavailable");
}

if (
    !runners ||
    typeof runners.register !== "function" ||
    typeof runners.get !== "function"
) {
    throw new Error("Runner® registry surface unavailable");
}

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

const queued = queue.get(requestId);

if (!queued) {
    throw new Error("Request was not established in Queue®");
}

runners.register({
    id: runnerId,
    name: "Queue Dispatch Lifecycle Runner®",
    status: "available"
});

state.create(requestId, {
    status: "queued",
    runnerId: null
});

const assignment = dispatch.assign({
    requestId,
    runnerId
});

if (!assignment) {
    throw new Error("Dispatch® assignment failed");
}

const assignedRequest = requests.get(requestId);
const dispatchState = state.get(requestId);
const runner = runners.get(runnerId);

if (!assignedRequest) {
    throw new Error("Assigned Request® disappeared");
}

if (!dispatchState) {
    throw new Error("Dispatch State® was not established");
}

if (!runner) {
    throw new Error("Runner® disappeared during dispatch");
}

if (
    assignedRequest.id !== requestId ||
    dispatchState.requestId !== requestId ||
    runner.currentRequestId !== requestId
) {
    throw new Error("Queue → Dispatch® → Runner® identity mismatch");
}

console.log("✓ Queue® → Dispatch® → Runner® assignment established");

if (typeof dispatch.release === "function") {
    dispatch.release({
        requestId,
        runnerId
    });
} else if (typeof dispatch.releaseRequest === "function") {
    dispatch.releaseRequest(requestId, runnerId);
} else if (typeof runners.setAvailable === "function") {
    runners.setAvailable(runnerId);
}

queue.remove(requestId);
requests.remove(requestId);
state.remove(requestId);

if (queue.get(requestId) !== null) {
    throw new Error("Queue® state leaked");
}

if (requests.get(requestId) !== null) {
    throw new Error("Request® state leaked");
}

if (state.get(requestId) !== null) {
    throw new Error("Dispatch State® leaked");
}

if (typeof runners.remove === "function") {
    runners.remove(runnerId);
}

console.log("✓ Queue® → Dispatch® isolated lifecycle cleared");
NODE
then
    ok "Queue® → Dispatch® lifecycle verified"
else
    bad "Queue® → Dispatch® lifecycle failed"
fi

echo
echo "[4] DISPATCH STATE CONSISTENCY"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const requests = require("./apps/request-runner/requests");
const queue = require("./apps/request-runner/request-queue");
const state = require("./apps/request-runner/dispatch-state");

const id = "__dispatch_state_consistency__";

requests.create({
    id,
    status: "created"
});

requests.update(id, {
    status: "queued"
});

queue.enqueue({
    id,
    priority: 75
});

state.create(id, {
    status: "queued",
    runnerId: null
});

const request = requests.get(id);
const queued = queue.get(id);
const dispatchState = state.get(id);

if (!request || request.status !== "queued") {
    throw new Error("Request® state inconsistent");
}

if (!queued || queued.id !== id) {
    throw new Error("Queue® identity inconsistent");
}

if (!dispatchState || dispatchState.requestId !== id) {
    throw new Error("Dispatch State® identity inconsistent");
}

state.update(id, {
    status: "assigned",
    runnerId: "__consistency_runner__"
});

const assigned = state.get(id);

if (
    !assigned ||
    assigned.status !== "assigned" ||
    assigned.runnerId !== "__consistency_runner__"
) {
    throw new Error("Dispatch State® assignment state inconsistent");
}

queue.remove(id);
requests.remove(id);
state.remove(id);

console.log("✓ Request® + Queue® + Dispatch State® consistency verified");
NODE
then
    ok "Dispatch State® consistency verified"
else
    bad "Dispatch State® consistency failed"
fi

echo
echo "[5] INVALID DISPATCH PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const state = require("./apps/request-runner/dispatch-state");

const id = "__invalid_dispatch_state__";

state.create(id, {
    status: "queued"
});

let rejected = false;

try {
    state.update(id, {
        status: "INVALID_DISPATCH_STATE"
    });
} catch (_) {
    rejected = true;
}

state.remove(id);

if (!rejected) {
    throw new Error("Invalid Dispatch State® was accepted");
}

console.log("✓ Invalid Dispatch State® rejected");
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

if (!app.runners) {
    throw new Error("Runner® surface missing");
}

if (!app.dispatch) {
    throw new Error("Dispatch® surface missing");
}

if (!app.dispatchState) {
    throw new Error("Dispatch State® surface missing");
}

if (!app.requestQueue) {
    throw new Error("Request Queue® surface missing");
}

const requests = require("./apps/request-runner/requests");

if (
    typeof requests.create !== "function" ||
    typeof requests.get !== "function" ||
    typeof requests.update !== "function"
) {
    throw new Error("Request® lifecycle surface missing");
}

console.log(
    "✓ Request® + Queue® + Dispatch® + State® + Runner® surface loaded"
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
echo " QUEUE → DISPATCH® LIFECYCLE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "QUEUE → DISPATCH® LIFECYCLE VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
