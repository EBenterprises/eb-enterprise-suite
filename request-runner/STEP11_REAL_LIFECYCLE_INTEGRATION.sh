#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================================="
echo " EB PLATFORM® — STEP 11 REAL LIFECYCLE INTEGRATION"
echo "=============================================================="

BACKUP=".backups/pre-real-lifecycle-20260810-143832"
test -d "$BACKUP"

echo
echo "[1] VERIFY BACKUP"
echo "✓ $BACKUP"

echo
echo "[2] BACK UP CURRENT DOMAIN SERVICE"

mkdir -p "$BACKUP/step11"

if [ ! -f "$BACKUP/step11/domain-service.js" ]; then
    cp -p api/domain-service.js "$BACKUP/step11/domain-service.js"
fi

echo "✓ Protected"

echo
echo "[3] RECONCILE ORDER STATE ALLOW-LIST"

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let s = fs.readFileSync(file, "utf8");

const oldBlock = `    const allowed = [
        "pending",
        "confirmed",
        "assigned",
        "en_route",
        "picked_up",
        "completed",
        "cancelled"
    ];`;

const newBlock = `    const allowed = [
        "pending",
        "confirmed",
        "assigned",
        "en_route",
        "arrived",
        "picked_up",
        "completed",
        "cancelled"
    ];`;

if (s.includes(newBlock)) {
    console.log("✓ Order allow-list already contains arrived");
} else if (s.includes(oldBlock)) {
    s = s.replace(oldBlock, newBlock);
    fs.writeFileSync(file, s);
    console.log("✓ Added order arrived state");
} else {
    throw new Error("Could not locate order status allow-list");
}
NODE

echo
echo "[4] SYNTAX"

node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js

echo "✓ Syntax valid"

echo
echo "[5] VERIFY CANONICAL GRAPH"

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
  l.assertRequestTransition(a,b);
}

for (const [a,b] of order) {
  l.assertOrderTransition(a,b);
}

console.log("✓ REQUEST lifecycle PASS");
console.log("✓ ORDER lifecycle PASS");
NODE

echo
echo "[6] HEALTH"

curl -fsS http://127.0.0.1:3000/api/health
echo

echo
echo "[7] CREATE ISOLATED TEST CUSTOMER"

CUSTOMER_RESPONSE=$(
curl -fsS \
  -X POST \
  http://127.0.0.1:3000/api/customers \
  -H 'Content-Type: application/json' \
  -d '{
    "name":"STEP11 Lifecycle Integration Customer",
    "phone":"0000000011"
  }'
)

echo "$CUSTOMER_RESPONSE"

CUSTOMER_ID=$(
printf '%s' "$CUSTOMER_RESPONSE" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const x=JSON.parse(s);
  const r=x.data || x.record;
  if (!r?.id) process.exit(1);
  process.stdout.write(r.id);
});
'
)

test -n "$CUSTOMER_ID"
echo "CUSTOMER_ID=$CUSTOMER_ID"

echo
echo "[8] CREATE ISOLATED REQUEST"

REQUEST_RESPONSE=$(
curl -fsS \
  -X POST \
  http://127.0.0.1:3000/api/requests \
  -H 'Content-Type: application/json' \
  -d "{
    \"customerId\":\"$CUSTOMER_ID\",
    \"pickup\":\"STEP11 PICKUP\",
    \"destination\":\"STEP11 DESTINATION\",
    \"notes\":\"STEP11 isolated lifecycle integration test\"
  }"
)

echo "$REQUEST_RESPONSE"

REQUEST_ID=$(
printf '%s' "$REQUEST_RESPONSE" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const x=JSON.parse(s);
  const r=x.data || x.record;
  if (!r?.id) process.exit(1);
  process.stdout.write(r.id);
});
'
)

test -n "$REQUEST_ID"
echo "REQUEST_ID=$REQUEST_ID"

echo
echo "[9] ACCEPT REQUEST"

ACCEPT_RESPONSE=$(
curl -fsS \
  -X POST \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID/accept"
)

echo "$ACCEPT_RESPONSE"

ORDER_ID=$(
printf '%s' "$ACCEPT_RESPONSE" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const x=JSON.parse(s);
  if (!x.order?.id) process.exit(1);
  process.stdout.write(x.order.id);
});
'
)

test -n "$ORDER_ID"
echo "ORDER_ID=$ORDER_ID"

echo
echo "[10] CREATE TEST DRIVER"

DRIVER_RESPONSE=$(
curl -fsS \
  -X POST \
  http://127.0.0.1:3000/api/drivers \
  -H 'Content-Type: application/json' \
  -d '{
    "name":"STEP11 Test Driver",
    "phone":"0000000011",
    "location":"STEP11 TEST"
  }'
)

echo "$DRIVER_RESPONSE"

DRIVER_ID=$(
printf '%s' "$DRIVER_RESPONSE" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const x=JSON.parse(s);
  const r=x.data || x.record;
  if (!r?.id) process.exit(1);
  process.stdout.write(r.id);
});
'
)

test -n "$DRIVER_ID"
echo "DRIVER_ID=$DRIVER_ID"

echo
echo "[11] ACCEPTED → ASSIGNED"

ASSIGN_CODE=$(
curl -s \
  -o /tmp/step11-assign.json \
  -w "%{http_code}" \
  -X POST \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID/assign" \
  -H 'Content-Type: application/json' \
  -d "{\"driverId\":\"$DRIVER_ID\"}"
)

cat /tmp/step11-assign.json
echo

test "$ASSIGN_CODE" = "200"

echo "✓ Driver assignment PASS"

echo
echo "[12] REQUEST: ASSIGNED → EN_ROUTE"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"en_route"}'

echo

echo
echo "[13] ORDER: ASSIGNED → EN_ROUTE"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/orders/$ORDER_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"en_route"}'

echo

echo
echo "[14] REQUEST: EN_ROUTE → ARRIVED"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"arrived"}'

echo

echo
echo "[15] ORDER: EN_ROUTE → ARRIVED"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/orders/$ORDER_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"arrived"}'

echo

echo
echo "[16] REQUEST: ARRIVED → PICKED_UP"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"picked_up"}'

echo

echo
echo "[17] ORDER: ARRIVED → PICKED_UP"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/orders/$ORDER_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"picked_up"}'

echo

echo
echo "[18] REQUEST: PICKED_UP → COMPLETED"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"completed"}'

echo

echo
echo "[19] ORDER: PICKED_UP → COMPLETED"

curl -fsS \
  -X PATCH \
  "http://127.0.0.1:3000/api/orders/$ORDER_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"completed"}'

echo

echo
echo "[20] FINAL REQUEST"

FINAL_REQUEST=$(curl -fsS \
  "http://127.0.0.1:3000/api/requests/$REQUEST_ID")

echo "$FINAL_REQUEST"

echo
echo "[21] FINAL ORDER"

FINAL_ORDER=$(curl -fsS \
  "http://127.0.0.1:3000/api/orders/$ORDER_ID")

echo "$FINAL_ORDER"

echo
echo "[22] ASSERT FINAL STATES"

printf '%s' "$FINAL_REQUEST" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const x=JSON.parse(s);
  const r=x.data || x.record;
  if (r.status !== "completed") {
    throw new Error("Request did not reach completed");
  }
  console.log("✓ Request completed");
});
'

printf '%s' "$FINAL_ORDER" |
node -e '
let s="";
process.stdin.on("data",d=>s+=d);
process.stdin.on("end",()=>{
  const x=JSON.parse(s);
  const r=x.data || x.record;
  if (r.status !== "completed") {
    throw new Error("Order did not reach completed");
  }
  console.log("✓ Order completed");
});
'

echo
echo "[23] TERMINAL STATE PROTECTION"

INVALID_CODE=$(
curl -s \
  -o /tmp/step11-invalid.json \
  -w "%{http_code}" \
  -X PATCH \
  "http://127.0.0.1:3000/api/orders/$ORDER_ID/status" \
  -H 'Content-Type: application/json' \
  -d '{"status":"pending"}'
)

cat /tmp/step11-invalid.json
echo

if [ "$INVALID_CODE" = "400" ]; then
    echo "✓ completed → pending blocked"
else
    echo "✗ Terminal protection failed"
    exit 1
fi

echo
echo "[24] FINAL HEALTH"

curl -fsS http://127.0.0.1:3000/api/health
echo

rm -f /tmp/step11-assign.json /tmp/step11-invalid.json

echo
echo "=============================================================="
echo " STEP 11 COMPLETE — REAL LIFECYCLE PASSED"
echo "=============================================================="
echo
echo "TEST CUSTOMER: $CUSTOMER_ID"
echo "TEST REQUEST:  $REQUEST_ID"
echo "TEST ORDER:    $ORDER_ID"
echo "TEST DRIVER:   $DRIVER_ID"
echo
echo "REQUEST:"
echo "pending → accepted → assigned → en_route → arrived → picked_up → completed"
echo
echo "ORDER:"
echo "pending → assigned → en_route → arrived → picked_up → completed"
echo
echo "Terminal protection: PASS"
echo "Existing pre-test records: untouched"
echo "server.js: untouched"
echo
echo "NEXT: STEP 12 — REALTIME EVENT + UI/OPS RECONCILIATION"
echo "=============================================================="
