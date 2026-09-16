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
echo " REQUEST RUNNER® — DISPATCH STATE® CONTRACT REPAIR"
echo " ADDITIVE / PRESERVE GREEN BASELINE"
echo "=============================================================="

echo
echo "[1] PRODUCTION BASELINE"
echo "--------------------------------------------------------------"

if ./FINAL_PRODUCTION_SNAPSHOT.sh >/dev/null 2>&1; then
    ok "Production baseline remains GREEN"
else
    bad "Production baseline failed"
    echo "STOP — baseline is not GREEN"
    exit 1
fi

echo
echo "[2] BACKUP"
echo "--------------------------------------------------------------"

BACKUP="apps/request-runner/.dispatch-state.js.contract-backup-$(date +%Y%m%d-%H%M%S)"

if cp apps/request-runner/dispatch-state.js "$BACKUP"; then
    ok "Dispatch State® backup created"
else
    bad "Dispatch State® backup failed"
    exit 1
fi

echo
echo "[3] DISPATCH STATE® CONTRACT"
echo "--------------------------------------------------------------"

cat > apps/request-runner/dispatch-state.js <<'STATE_EOF'
const states = new Map();

const VALID_STATES = Object.freeze([
    "queued",
    "assigned",
    "in_progress",
    "completed",
    "cancelled",
    "failed"
]);

function normalize(requestId, input = {}) {
    if (!requestId) {
        throw new Error("Request id is required");
    }

    if (!input || typeof input !== "object") {
        throw new Error("Dispatch state must be an object");
    }

    const status = input.status || "queued";

    if (!VALID_STATES.includes(status)) {
        throw new Error(`Invalid Dispatch state: ${status}`);
    }

    return {
        ...input,
        requestId: String(requestId),
        status,
        runnerId:
            input.runnerId === undefined
                ? null
                : input.runnerId,
        createdAt:
            input.createdAt ||
            new Date().toISOString(),
        updatedAt:
            new Date().toISOString()
    };
}

function create(requestId, input = {}) {
    const id = String(requestId);

    if (states.has(id)) {
        throw new Error(`Dispatch state already exists: ${id}`);
    }

    const state = normalize(id, input);

    states.set(id, state);

    return { ...state };
}

function get(requestId) {
    if (!requestId) {
        return null;
    }

    const state = states.get(String(requestId));

    return state ? { ...state } : null;
}

function update(requestId, patch = {}) {
    const id = String(requestId);

    if (!states.has(id)) {
        throw new Error(`Dispatch state not found: ${requestId}`);
    }

    const current = states.get(id);

    let changes;

    if (typeof patch === "string") {
        changes = {
            status: patch
        };
    } else if (patch && typeof patch === "object") {
        changes = {
            ...patch
        };
    } else {
        throw new Error(
            "Dispatch state update must be an object or state"
        );
    }

    if (
        Object.prototype.hasOwnProperty.call(
            changes,
            "status"
        ) &&
        !VALID_STATES.includes(changes.status)
    ) {
        throw new Error(
            `Invalid Dispatch state: ${changes.status}`
        );
    }

    const updated = {
        ...current,
        ...changes,
        requestId: id,
        updatedAt: new Date().toISOString()
    };

    states.set(id, updated);

    return { ...updated };
}

function remove(requestId) {
    return states.delete(String(requestId));
}

function list() {
    return Array.from(states.values()).map(
        state => ({ ...state })
    );
}

function clear() {
    states.clear();
}

module.exports = {
    name: "dispatch-state",
    VALID_STATES,
    create,
    get,
    update,
    remove,
    list,
    clear
};
STATE_EOF

ok "Dispatch State® contract installed"

echo
echo "[4] SYNTAX"
echo "--------------------------------------------------------------"

if node --check apps/request-runner/dispatch-state.js >/dev/null 2>&1; then
    ok "Dispatch State® syntax valid"
else
    bad "Dispatch State® syntax failed"
fi

echo
echo "[5] STATE TRANSITION CONTRACT"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const state = require("./apps/request-runner/dispatch-state");

const id = "__dispatch_state_repair__";

state.create(id, {
    status: "queued",
    runnerId: null
});

let current = state.get(id);

if (!current || current.status !== "queued") {
    throw new Error("Queued state failed");
}

state.update(id, {
    status: "assigned",
    runnerId: "__repair_runner__"
});

current = state.get(id);

if (
    !current ||
    current.status !== "assigned" ||
    current.runnerId !== "__repair_runner__"
) {
    throw new Error("Assigned state failed");
}

state.update(id, {
    status: "in_progress"
});

current = state.get(id);

if (!current || current.status !== "in_progress") {
    throw new Error("In-progress state failed");
}

state.update(id, {
    status: "completed"
});

current = state.get(id);

if (!current || current.status !== "completed") {
    throw new Error("Completed state failed");
}

state.remove(id);

if (state.get(id) !== null) {
    throw new Error("Dispatch State® test state leaked");
}

console.log("✓ Dispatch State® lifecycle verified");
NODE
then
    ok "Dispatch State® lifecycle contract verified"
else
    bad "Dispatch State® lifecycle contract failed"
fi

echo
echo "[6] INVALID STATE PROTECTION"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const state = require("./apps/request-runner/dispatch-state");

const id = "__invalid_dispatch_state_repair__";

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
    throw new Error(
        "Invalid Dispatch State® was accepted"
    );
}

console.log("✓ Invalid Dispatch State® rejected");
NODE
then
    ok "Invalid Dispatch State® protection verified"
else
    bad "Invalid Dispatch State® protection failed"
fi

echo
echo "[7] APPLICATION SURFACE"
echo "--------------------------------------------------------------"

if node - <<'NODE'
const app = require("./apps/request-runner");
const state = require("./apps/request-runner/dispatch-state");

if (!app || typeof app !== "object") {
    throw new Error("Application failed to load");
}

if (!app.requestQueue) {
    throw new Error("Request Queue® surface missing");
}

if (!app.dispatch) {
    throw new Error("Dispatch® surface missing");
}

if (!app.runners) {
    throw new Error("Runner® surface missing");
}

if (
    typeof state.create !== "function" ||
    typeof state.get !== "function" ||
    typeof state.update !== "function" ||
    typeof state.remove !== "function"
) {
    throw new Error(
        "Dispatch State® lifecycle surface missing"
    );
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
echo " DISPATCH STATE® REPAIR RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "DISPATCH STATE® CONTRACT REPAIRED"
    echo "READY FOR VERIFICATION"
else
    echo "STATUS: RED"
    echo "STOP — DO NOT ADVANCE"
    exit 1
fi

echo "=============================================================="
