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
echo " REQUEST RUNNER® — REQUEST LIFECYCLE® VERIFICATION"
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
echo "[2] REQUEST MODULE"
echo "--------------------------------------------------------------"

if [ -f apps/request-runner/requests.js ] &&
   node --check apps/request-runner/requests.js >/dev/null 2>&1; then
    ok "Request® module valid"
else
    bad "Request® module missing or invalid"
fi

echo
echo "[3] REQUEST LIFECYCLE SURFACE"
echo "--------------------------------------------------------------"

node - <<'NODE'
const requests = require("./apps/request-runner/requests");

if (!requests || typeof requests !== "object") {
    throw new Error("Request® service unavailable");
}

const keys = Object.keys(requests);

console.log("Request® exports:");
console.log(keys.sort().join(", ") || "(none)");
NODE

if [ "$?" -eq 0 ]; then
    ok "Request® service loaded"
else
    bad "Request® service unavailable"
fi

echo
echo "[4] REQUEST LIFECYCLE CONTRACT"
echo "--------------------------------------------------------------"

if node - <<'NODE2'
const requests = require("./apps/request-runner/requests");

const id = "__lifecycle_request__";

const create =
    requests.create ||
    requests.register ||
    requests.add ||
    requests.submit;

const get =
    requests.get ||
    requests.find ||
    requests.retrieve;

const update =
    requests.update ||
    requests.setStatus ||
    requests.transition ||
    requests.changeStatus;

const remove =
    requests.remove ||
    requests.delete;

if (
    typeof create !== "function" ||
    typeof get !== "function" ||
    typeof update !== "function" ||
    typeof remove !== "function"
) {
    throw new Error("Complete Request® lifecycle surface unavailable");
}

/*
 * Request® uses an in-memory registry.
 * Therefore creation, transition, retrieval and cleanup
 * must occur inside this single Node process.
 */

create.call(requests, {
    id,
    status: "created"
});

let request = get.call(requests, id);

if (!request || request.status !== "created") {
    throw new Error("Request creation/retrieval failed");
}

console.log("✓ Request® creation/retrieval verified");

for (const status of [
    "queued",
    "assigned",
    "in_progress",
    "completed"
]) {
    let result;

    try {
        result = update.call(requests, id, { status });
    } catch (_) {
        result = update.call(requests, id, status);
    }

    if (!result) {
        throw new Error(`Request transition failed: ${status}`);
    }

    request = get.call(requests, id);

    if (!request || request.status !== status) {
        throw new Error(`Request state not established: ${status}`);
    }
}

console.log("✓ Request® lifecycle transitions verified");

if (!remove.call(requests, id)) {
    throw new Error("Request lifecycle cleanup failed");
}

if (get.call(requests, id) !== null) {
    throw new Error("Request lifecycle test state leaked");
}

console.log("✓ Isolated Request® lifecycle state cleared");
NODE2
then
    ok "Request® lifecycle contract verified"
else
    bad "Request® lifecycle contract failed"
fi

echo
echo "[5] INVALID STATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE2'
const requests = require("./apps/request-runner/requests");

const id = "__invalid_request_state_test__";

requests.create({
    id,
    status: "created"
});

let rejected = false;

try {
    requests.update(id, {
        status: "INVALID_STATE"
    });
} catch (_) {
    rejected = true;
}

requests.remove(id);

if (!rejected) {
    throw new Error("Invalid Request® state was accepted");
}

console.log("✓ Invalid Request® states rejected");
NODE2
then
    ok "Invalid Request® state protection verified"
else
    bad "Invalid Request® state protection failed"
fi

echo
echo "[6] TEST STATE CLEANUP"
echo "--------------------------------------------------------------"

node - <<'NODE'
const requests = require("./apps/request-runner/requests");

const id = "__lifecycle_request__";

if (typeof requests.remove === "function") {
    requests.remove(id);
} else if (typeof requests.delete === "function") {
    requests.delete(id);
} else if (typeof requests.clear === "function") {
    /*
     * Do not clear the production registry if no targeted
     * removal operation exists.
     */
    console.log("⚠ No targeted Request® removal operation");
}

const get =
    requests.get ||
    requests.find ||
    requests.retrieve;

if (typeof get === "function" && get.call(requests, id)) {
    throw new Error("Lifecycle test state leaked");
}

console.log("✓ Isolated Request® lifecycle state cleared");
NODE

if [ "$?" -eq 0 ]; then
    ok "No lifecycle test state leaked"
else
    bad "Lifecycle test state leaked"
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
echo " REQUEST LIFECYCLE® RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST LIFECYCLE® VERIFIED"
    echo "READY FOR NEXT PRODUCT SURFACE"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
