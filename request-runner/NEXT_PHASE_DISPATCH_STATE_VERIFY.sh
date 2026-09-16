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
echo " REQUEST RUNNER® — DISPATCH® STATE VERIFICATION"
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
echo "[2] DISPATCH STATE MODULE"
echo "--------------------------------------------------------------"

if [ -f apps/request-runner/dispatch-state.js ] &&
   node --check apps/request-runner/dispatch-state.js >/dev/null 2>&1; then
    ok "Dispatch® state module valid"
else
    bad "Dispatch® state module missing or invalid"
fi

echo
echo "[3] STATE LIFECYCLE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.dispatchState) {
    throw new Error("Dispatch state service unavailable");
}

const state = app.dispatchState;

const requestId = "__state_verify_request__";
const runnerId = "__state_verify_runner__";

state.create(requestId, {
    state: "queued"
});

if (state.get(requestId).state !== "queued") {
    throw new Error("Queued state failed");
}

state.update(requestId, {
    state: "dispatched",
    runnerId
});

let record = state.get(requestId);

if (record.state !== "dispatched") {
    throw new Error("Dispatched state failed");
}

if (record.runnerId !== runnerId) {
    throw new Error("Runner association failed");
}

state.update(requestId, {
    state: "accepted"
});

state.update(requestId, {
    state: "in_progress"
});

state.update(requestId, {
    state: "completed"
});

record = state.get(requestId);

if (record.state !== "completed") {
    throw new Error("Completed state failed");
}

if (record.runnerId !== runnerId) {
    throw new Error("Runner association lost");
}

state.remove(requestId);

if (state.get(requestId) !== null) {
    throw new Error("Isolated state was not removed");
}

console.log("✓ Dispatch® state lifecycle verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[4] INVALID STATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const state = require("./apps/request-runner/dispatch-state");

const id = "__invalid_state_verify__";
let rejected = false;

try {
    state.create(id, {
        state: "invalid_state"
    });
} catch (_) {
    rejected = true;
}

state.remove(id);

if (!rejected) {
    throw new Error("Invalid dispatch state was accepted");
}

console.log("✓ Invalid dispatch states rejected");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[5] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners) {
    throw new Error("Runner® export missing");
}

if (!app.dispatchRunner) {
    throw new Error("Dispatch® export missing");
}

if (!app.dispatchState) {
    throw new Error("Dispatch state export missing");
}

console.log("✓ Runner® + Dispatch® + State® surface loaded");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[6] LOCAL SERVER"
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
echo " DISPATCH® STATE PHASE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "DISPATCH® STATE VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
