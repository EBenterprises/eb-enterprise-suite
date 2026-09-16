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
echo " REQUEST RUNNER® — REQUEST QUEUE® VERIFICATION"
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
echo "[2] QUEUE MODULE"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/request-queue.js >/dev/null 2>&1; then
    ok "Request Queue® module syntax valid"
else
    bad "Request Queue® module invalid"
fi

echo
echo "[3] PRIORITY ORDERING"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const queue = require("./apps/request-runner/request-queue");

queue.clear();

queue.enqueue({
    id: "__queue_low__",
    priority: 1
});

queue.enqueue({
    id: "__queue_high__",
    priority: 100
});

if (queue.peek().id !== "__queue_high__") {
    throw new Error("Priority ordering failed");
}

const first = queue.dequeue();

if (first.id !== "__queue_high__") {
    throw new Error("Priority dequeue failed");
}

queue.clear();

console.log("✓ Priority queue ordering verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[4] QUEUE LIFECYCLE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const queue = require("./apps/request-runner/request-queue");

queue.clear();

const id = "__queue_lifecycle__";

queue.enqueue({
    id,
    priority: 10,
    capabilities: ["standard"]
});

if (queue.size() !== 1) {
    throw new Error("Queue insertion failed");
}

if (!queue.get(id)) {
    throw new Error("Queued Request® lookup failed");
}

const item = queue.dequeue();

if (!item || item.id !== id) {
    throw new Error("Queue dequeue failed");
}

if (queue.size() !== 0) {
    throw new Error("Queue did not empty");
}

queue.clear();

console.log("✓ Request Queue® lifecycle verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[5] DUPLICATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const queue = require("./apps/request-runner/request-queue");

queue.clear();

const id = "__queue_duplicate__";

queue.enqueue({ id });

let rejected = false;

try {
    queue.enqueue({ id });
} catch (_) {
    rejected = true;
}

queue.clear();

if (!rejected) {
    throw new Error("Duplicate Request® accepted");
}

console.log("✓ Duplicate Request® protection verified");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo
echo "[6] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app.runners)
    throw new Error("Runner® export missing");

if (!app.dispatchRunner)
    throw new Error("Dispatch® export missing");

if (!app.dispatchState)
    throw new Error("Dispatch State® export missing");

if (!app.requestQueue)
    throw new Error("Request Queue® export missing");

console.log("✓ Runner® + Dispatch® + State® + Queue® surface loaded");
NODE
then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
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
echo "=============================================================="
echo " REQUEST QUEUE® PHASE RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST QUEUE® VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
