#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 7 — BUILD LIFECYCLE BRIDGE ==="

mkdir -p framework/lifecycle

cat > framework/lifecycle/canonical.js <<'LIFECYCLE'
const REQUEST_STATES = [
    "pending",
    "accepted",
    "assigned",
    "en_route",
    "arrived",
    "picked_up",
    "completed",
    "cancelled"
];

const ORDER_STATES = [
    "pending",
    "confirmed",
    "assigned",
    "en_route",
    "arrived",
    "picked_up",
    "completed",
    "cancelled"
];

const TRANSITIONS = {
    pending: ["accepted", "cancelled"],
    accepted: ["assigned", "cancelled"],
    confirmed: ["assigned", "cancelled"],
    assigned: ["en_route", "cancelled"],
    en_route: ["arrived", "cancelled"],
    arrived: ["picked_up", "cancelled"],
    picked_up: ["completed", "cancelled"],
    completed: [],
    cancelled: []
};

function allowedStates(type) {
    return type === "order"
        ? ORDER_STATES
        : REQUEST_STATES;
}

function canTransition(type, from, to) {
    const states = allowedStates(type);

    if (!states.includes(from) || !states.includes(to)) {
        return false;
    }

    if (from === to) {
        return true;
    }

    return (TRANSITIONS[from] || []).includes(to);
}

function assertTransition(type, from, to) {
    if (!canTransition(type, from, to)) {
        throw new Error(
            `Invalid ${type} lifecycle transition: ${from} -> ${to}`
        );
    }

    return true;
}

module.exports = {
    REQUEST_STATES,
    ORDER_STATES,
    TRANSITIONS,
    allowedStates,
    canTransition,
    assertTransition
};
LIFECYCLE

echo
echo "[VERIFY]"
node - <<'NODE'
const x = require("./framework/lifecycle/canonical");

console.log("request states:", x.REQUEST_STATES.length);
console.log("order states:", x.ORDER_STATES.length);
console.log("pending -> accepted:", x.canTransition("request", "pending", "accepted"));
console.log("accepted -> assigned:", x.canTransition("order", "accepted", "assigned"));
console.log("assigned -> en_route:", x.canTransition("order", "assigned", "en_route"));
console.log("en_route -> arrived:", x.canTransition("order", "en_route", "arrived"));
console.log("arrived -> picked_up:", x.canTransition("order", "arrived", "picked_up"));
console.log("picked_up -> completed:", x.canTransition("order", "picked_up", "completed"));
console.log("completed -> pending:", x.canTransition("order", "completed", "pending"));
NODE

echo
echo "=== STEP 7 COMPLETE — LIFECYCLE MODULE CREATED ==="
echo "Existing data: untouched"
echo "server.js: untouched"
echo "Backup: untouched"
