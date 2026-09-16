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
echo " REQUEST RUNNER® — REQUEST LIFECYCLE® REPAIR"
echo " ADDITIVE / PRESERVE GREEN BASELINE"
echo "=============================================================="

echo
echo "[1] PRODUCTION BASELINE"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed"
    echo
    echo "STOP — baseline is not GREEN"
    exit 1
fi

echo
echo "[2] BACKUP"
echo "--------------------------------------------------------------"

BACKUP="apps/request-runner/.requests.js.lifecycle-backup-$(date +%Y%m%d-%H%M%S)"

if cp apps/request-runner/requests.js "$BACKUP"; then
    ok "Request® module backup created"
else
    bad "Request® module backup failed"
    exit 1
fi

echo
echo "[3] REQUEST® REGISTRY"
echo "--------------------------------------------------------------"

cat > apps/request-runner/requests.js <<'REQUESTS_EOF'
const requests = new Map();

const VALID_STATES = new Set([
    "created",
    "queued",
    "assigned",
    "in_progress",
    "completed",
    "cancelled",
    "failed"
]);

function normalize(input = {}) {
    if (!input || typeof input !== "object") {
        throw new Error("Request must be an object");
    }

    if (!input.id) {
        throw new Error("Request id is required");
    }

    const id = String(input.id);

    const status = input.status || "created";

    if (!VALID_STATES.has(status)) {
        throw new Error(`Invalid Request state: ${status}`);
    }

    return {
        ...input,
        id,
        status,
        createdAt: input.createdAt || new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };
}

function create(input = {}) {
    const item = normalize(input);

    if (requests.has(item.id)) {
        throw new Error(`Request already exists: ${item.id}`);
    }

    requests.set(item.id, item);

    return { ...item };
}

function get(id) {
    if (!id) {
        return null;
    }

    const item = requests.get(String(id));

    return item ? { ...item } : null;
}

function update(id, patch = {}) {
    const key = String(id);

    if (!requests.has(key)) {
        throw new Error(`Request not found: ${id}`);
    }

    let changes;

    if (typeof patch === "string") {
        changes = { status: patch };
    } else if (patch && typeof patch === "object") {
        changes = { ...patch };
    } else {
        throw new Error("Request update must be an object or state");
    }

    if (
        Object.prototype.hasOwnProperty.call(changes, "status") &&
        !VALID_STATES.has(changes.status)
    ) {
        throw new Error(`Invalid Request state: ${changes.status}`);
    }

    const current = requests.get(key);

    const updated = {
        ...current,
        ...changes,
        id: key,
        updatedAt: new Date().toISOString()
    };

    requests.set(key, updated);

    return { ...updated };
}

function remove(id) {
    return requests.delete(String(id));
}

function list() {
    return Array.from(requests.values()).map(item => ({ ...item }));
}

function clear() {
    requests.clear();
}

module.exports = {
    name: "requests",

    VALID_STATES: Object.freeze(Array.from(VALID_STATES)),

    create,
    get,
    update,
    remove,
    list,
    clear,

    async initialize(app) {
        app.health.register("requests", async () => ({
            module: "requests",
            count: requests.size
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
REQUESTS_EOF

ok "Request® registry added"

echo
echo "[4] SYNTAX"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/requests.js >/dev/null 2>&1; then
    ok "Request® module syntax valid"
else
    bad "Request® module syntax failed"
fi

echo
echo "[5] REQUEST® CONTRACT"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const requests = require("./apps/request-runner/requests");

const id = "__repair_request_lifecycle__";

if (typeof requests.create !== "function") {
    throw new Error("create() unavailable");
}

if (typeof requests.get !== "function") {
    throw new Error("get() unavailable");
}

if (typeof requests.update !== "function") {
    throw new Error("update() unavailable");
}

if (typeof requests.remove !== "function") {
    throw new Error("remove() unavailable");
}

requests.create({
    id,
    status: "created"
});

let request = requests.get(id);

if (!request || request.status !== "created") {
    throw new Error("Request creation/retrieval failed");
}

for (const status of [
    "queued",
    "assigned",
    "in_progress",
    "completed"
]) {
    requests.update(id, { status });

    request = requests.get(id);

    if (!request || request.status !== status) {
        throw new Error(`Transition failed: ${status}`);
    }
}

if (!requests.remove(id)) {
    throw new Error("Request removal failed");
}

if (requests.get(id) !== null) {
    throw new Error("Request lifecycle test state leaked");
}

console.log("✓ Request® create/get/update/remove lifecycle verified");
NODE
then
    ok "Request® lifecycle contract verified"
else
    bad "Request® lifecycle contract failed"
fi

echo
echo "[6] INVALID STATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
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
    throw new Error("Invalid Request state was accepted");
}

console.log("✓ Invalid Request® states rejected");
NODE
then
    ok "Invalid Request® state protection verified"
else
    bad "Invalid Request® state protection failed"
fi

echo
echo "[7] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");

if (!app || typeof app !== "object") {
    throw new Error("Application failed to load");
}

const requests = require("./apps/request-runner/requests");

if (!requests.create || !requests.get || !requests.update) {
    throw new Error("Request® lifecycle surface unavailable");
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

console.log("✓ Request® + Queue® + Dispatch® + Runner® surface loaded");
NODE
then
    ok "Application surface remains intact"
else
    bad "Application surface failed"
fi

echo
echo "[8] LOCAL SERVER"
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
echo "[9] PRODUCTION BASELINE RECHECK"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed after repair"
fi

echo
echo "=============================================================="
echo " REQUEST LIFECYCLE® REPAIR RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "REQUEST LIFECYCLE® SURFACE REPAIRED"
    echo "READY FOR VERIFICATION"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
