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
echo " REQUEST RUNNER® — REQUEST → QUEUE® LIFECYCLE VERIFICATION"
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
    apps/request-runner/runners.js
do
    if [ -f "$file" ] && node --check "$file" >/dev/null 2>&1; then
        ok "$file valid"
    else
        bad "$file missing or invalid"
    fi
done

echo
echo "[3] REQUEST → QUEUE CONTRACT"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const requests = require("./apps/request-runner/requests");
const queue = require("./apps/request-runner/request-queue");

const id = "__request_queue_lifecycle__";

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
    throw new Error("Request Queue® lifecycle surface unavailable");
}

requests.create({
    id,
    status: "created",
    priority: 100
});

let request = requests.get(id);

if (!request || request.status !== "created") {
    throw new Error("Request creation failed");
}

requests.update(id, {
    status: "queued"
});

request = requests.get(id);

if (!request || request.status !== "queued") {
    throw new Error("Request queued state was not established");
}

queue.enqueue({
    id,
    priority: 100
});

const queued = queue.get(id);

if (!queued || queued.id !== id) {
    throw new Error("Request was not placed in Queue®");
}

console.log("✓ Request® → Queue® lifecycle established");

queue.remove(id);
requests.remove(id);

if (queue.get(id) !== null) {
    throw new Error("Queue® test state leaked");
}

if (requests.get(id) !== null) {
    throw new Error("Request® test state leaked");
}

console.log("✓ Request® + Queue® isolated state cleared");
NODE
then
    ok "Request® → Queue® lifecycle verified"
else
    bad "Request® → Queue® lifecycle failed"
fi

echo
echo "[4] QUEUE STATE CONSISTENCY"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const requests = require("./apps/request-runner/requests");
const queue = require("./apps/request-runner/request-queue");

const id = "__queue_state_consistency__";

requests.create({
    id,
    status: "created"
});

requests.update(id, {
    status: "queued"
});

queue.enqueue({
    id,
    priority: 50
});

const request = requests.get(id);
const queued = queue.get(id);

if (!request || request.status !== "queued") {
    throw new Error("Request® queued state inconsistent");
}

if (!queued || queued.id !== request.id) {
    throw new Error("Queue® Request® identity mismatch");
}

queue.remove(id);
requests.remove(id);

console.log("✓ Request® and Queue® state consistency verified");
NODE
then
    ok "Queue® state consistency verified"
else
    bad "Queue® state consistency failed"
fi

echo
echo "[5] DUPLICATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const requests = require("./apps/request-runner/requests");
const queue = require("./apps/request-runner/request-queue");

const id = "__queue_duplicate_test__";

requests.create({
    id,
    status: "created"
});

queue.enqueue({
    id,
    priority: 25
});

let rejected = false;

try {
    queue.enqueue({
        id,
        priority: 25
    });
} catch (_) {
    rejected = true;
}

queue.remove(id);
requests.remove(id);

if (!rejected) {
    throw new Error("Duplicate Request® was accepted by Queue®");
}

console.log("✓ Duplicate Request® protection verified");
NODE
then
    ok "Duplicate Request® protection verified"
else
    bad "Duplicate Request® protection failed"
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

console.log("✓ Request® + Queue® + Dispatch® + State® + Runner® surface loaded");
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
echo " REQUEST → QUEUE® LIFECYCLE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST → QUEUE® LIFECYCLE VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
