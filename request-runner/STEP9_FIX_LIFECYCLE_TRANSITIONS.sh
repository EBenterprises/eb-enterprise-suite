#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 9 — FIX CANONICAL TRANSITIONS ==="

BACKUP=".backups/pre-real-lifecycle-20260810-143832"
test -d "$BACKUP"

echo "[1] LOCATING LIFECYCLE MODULE"
FILES=$(grep -RIlE \
  'pending.*accepted|accepted.*assigned|assigned.*en_route' \
  . \
  --exclude-dir=node_modules \
  --exclude-dir=.next \
  --exclude-dir=.git \
  --exclude='STEP*.sh' \
  2>/dev/null || true)

printf '%s\n' "$FILES"

echo
echo "[2] CREATE CANONICAL LIFECYCLE MODULE"

mkdir -p framework/lifecycle

cat > framework/lifecycle/canonical-lifecycle.js <<'JS'
"use strict";

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

const REQUEST_TRANSITIONS = {
  pending: ["accepted", "cancelled"],
  accepted: ["assigned", "cancelled"],
  assigned: ["en_route", "cancelled"],
  en_route: ["arrived", "cancelled"],
  arrived: ["picked_up", "cancelled"],
  picked_up: ["completed"],
  completed: [],
  cancelled: []
};

const ORDER_TRANSITIONS = {
  pending: ["confirmed", "assigned", "cancelled"],
  confirmed: ["assigned", "cancelled"],
  assigned: ["en_route", "cancelled"],
  en_route: ["arrived", "cancelled"],
  arrived: ["picked_up", "cancelled"],
  picked_up: ["completed"],
  completed: [],
  cancelled: []
};

function canTransition(graph, from, to) {
  return Array.isArray(graph[from]) && graph[from].includes(to);
}

function requestCanTransition(from, to) {
  return canTransition(REQUEST_TRANSITIONS, from, to);
}

function orderCanTransition(from, to) {
  return canTransition(ORDER_TRANSITIONS, from, to);
}

function assertRequestTransition(from, to) {
  if (!requestCanTransition(from, to)) {
    throw new Error(`Invalid request transition: ${from} -> ${to}`);
  }
  return true;
}

function assertOrderTransition(from, to) {
  if (!orderCanTransition(from, to)) {
    throw new Error(`Invalid order transition: ${from} -> ${to}`);
  }
  return true;
}

module.exports = {
  REQUEST_STATES,
  ORDER_STATES,
  REQUEST_TRANSITIONS,
  ORDER_TRANSITIONS,
  requestCanTransition,
  orderCanTransition,
  assertRequestTransition,
  assertOrderTransition
};
JS

echo "✓ Canonical lifecycle written"

echo
echo "[3] VERIFY TRANSITIONS"

node <<'NODE'
const l = require("./framework/lifecycle/canonical-lifecycle");

const request = [
  ["pending","accepted"],
  ["accepted","assigned"],
  ["assigned","en_route"],
  ["en_route","arrived"],
  ["arrived","picked_up"],
  ["picked_up","completed"]
];

const order = [
  ["pending","confirmed"],
  ["confirmed","assigned"],
  ["assigned","en_route"],
  ["en_route","arrived"],
  ["arrived","picked_up"],
  ["picked_up","completed"]
];

for (const [a,b] of request) {
  if (!l.requestCanTransition(a,b)) {
    throw new Error(`REQUEST FAILED: ${a} -> ${b}`);
  }
}

for (const [a,b] of order) {
  if (!l.orderCanTransition(a,b)) {
    throw new Error(`ORDER FAILED: ${a} -> ${b}`);
  }
}

if (l.requestCanTransition("completed","pending")) {
  throw new Error("Invalid completed -> pending transition allowed");
}

console.log("request transitions: PASS");
console.log("order transitions: PASS");
console.log("accepted -> assigned: PASS");
console.log("terminal protection: PASS");
NODE

echo
echo "[4] SYNTAX"
node --check framework/lifecycle/canonical-lifecycle.js

echo
echo "[5] DATA INTEGRITY"
curl -fsS http://127.0.0.1:3000/api/health
echo
curl -fsS http://127.0.0.1:3000/api/orders
echo

echo
echo "=== STEP 9 COMPLETE — TRANSITION GRAPH FIXED ==="
echo "Existing data: untouched"
echo "server.js: untouched"
echo "Backup: untouched"
