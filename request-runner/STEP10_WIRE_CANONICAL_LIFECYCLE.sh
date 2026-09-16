#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================================="
echo " EB PLATFORM® — STEP 10 WIRE CANONICAL LIFECYCLE"
echo "=============================================================="

BACKUP=".backups/pre-real-lifecycle-20260810-143832"
test -d "$BACKUP"

echo
echo "[1] BACKUP VERIFIED"
echo "✓ $BACKUP"

echo
echo "[2] VERIFY CANONICAL MODULE"

node --check framework/lifecycle/canonical-lifecycle.js

node <<'NODE'
const lifecycle = require("./framework/lifecycle/canonical-lifecycle");

const requestPath = [
  ["pending","accepted"],
  ["accepted","assigned"],
  ["assigned","en_route"],
  ["en_route","arrived"],
  ["arrived","picked_up"],
  ["picked_up","completed"]
];

const orderPath = [
  ["pending","confirmed"],
  ["confirmed","assigned"],
  ["assigned","en_route"],
  ["en_route","arrived"],
  ["arrived","picked_up"],
  ["picked_up","completed"]
];

for (const [from,to] of requestPath) {
  lifecycle.assertRequestTransition(from,to);
}

for (const [from,to] of orderPath) {
  lifecycle.assertOrderTransition(from,to);
}

console.log("✓ Canonical transition graph valid");
NODE

echo
echo "[3] VERIFY DOMAIN SERVICE BACKUP"

mkdir -p "$BACKUP/step10"

if [ ! -f "$BACKUP/step10/domain-service.js" ]; then
    cp -p api/domain-service.js "$BACKUP/step10/domain-service.js"
fi

echo "✓ api/domain-service.js protected"

echo
echo "[4] PATCH DOMAIN SERVICE WITH NODE"

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let s = fs.readFileSync(file, "utf8");

const importAnchor = 'const store = require("./store");';

const importReplacement = `const store = require("./store");

const {
    assertRequestTransition,
    assertOrderTransition
} = require("../framework/lifecycle/canonical-lifecycle");`;

if (!s.includes(importAnchor)) {
    throw new Error("Cannot locate domain-service import anchor");
}

if (!s.includes("assertRequestTransition")) {
    s = s.replace(importAnchor, importReplacement);
}

const oldRequest = `    return store.update("requests", requestId, {
        status
    });`;

const newRequest = `    assertRequestTransition(request.status, status);

    return store.update("requests", requestId, {
        status
    });`;

if (!s.includes("assertRequestTransition(request.status, status)")) {
    if (!s.includes(oldRequest)) {
        throw new Error("Cannot locate request status update");
    }

    s = s.replace(oldRequest, newRequest);
}

const oldOrder = `    return store.update("orders", orderId, {
        status
    });`;

const newOrder = `    assertOrderTransition(order.status, status);

    return store.update("orders", orderId, {
        status
    });`;

if (!s.includes("assertOrderTransition(order.status, status)")) {
    if (!s.includes(oldOrder)) {
        throw new Error("Cannot locate order status update");
    }

    s = s.replace(oldOrder, newOrder);
}

const oldAssign = `    const updated = store.update("requests", requestId, {
        assignedDriverId: driverId,
        status: "assigned"
    });`;

const newAssign = `    assertRequestTransition(request.status, "assigned");

    const updated = store.update("requests", requestId, {
        assignedDriverId: driverId,
        status: "assigned"
    });`;

if (!s.includes("assertRequestTransition(request.status, \"assigned\")")) {
    if (!s.includes(oldAssign)) {
        throw new Error("Cannot locate driver assignment transition");
    }

    s = s.replace(oldAssign, newAssign);
}

fs.writeFileSync(file, s);

console.log("✓ Domain service patched");
NODE

echo
echo "[5] SYNTAX VALIDATION"

node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js

echo "✓ JavaScript syntax valid"

echo
echo "[6] VERIFY WIRING"

grep -n \
  -E 'canonical-lifecycle|assertRequestTransition|assertOrderTransition' \
  api/domain-service.js

echo
echo "[7] HEALTH"

curl -fsS http://127.0.0.1:3000/api/health
echo

echo
echo "[8] VERIFY EXISTING DATA COUNTS BEFORE TEST"

curl -fsS http://127.0.0.1:3000/api/requests
echo

curl -fsS http://127.0.0.1:3000/api/orders
echo

echo
echo "=============================================================="
echo " STEP 10 PATCH COMPLETE"
echo "=============================================================="
echo "Canonical lifecycle is now wired into domain status transitions."
echo "No test records were created."
echo "No existing records were modified."
echo "server.js untouched."
echo "Backup untouched."
echo
echo "NEXT: STEP 11 — REAL DRIVER ASSIGNMENT + FULL LIFECYCLE TEST"
echo "=============================================================="
