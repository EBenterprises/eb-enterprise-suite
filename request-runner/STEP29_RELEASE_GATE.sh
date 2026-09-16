#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 29 — RELEASE GATE ==="

node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js
node --check realtime-server.js

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

node <<'NODE'
const fs=require("fs");

for(const f of [
  "data/customers.json",
  "data/requests.json",
  "data/orders.json",
  "data/drivers.json"
]){
  JSON.parse(fs.readFileSync(f,"utf8"));
}

const l=require("./framework/lifecycle/canonical-lifecycle");

const req=[
 ["pending","accepted"],
 ["accepted","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
];

const ord=[
 ["pending","confirmed"],
 ["confirmed","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
];

for(const x of req)
  if(!l.requestCanTransition(...x)) throw Error("Request lifecycle failed");

for(const x of ord)
  if(!l.orderCanTransition(...x)) throw Error("Order lifecycle failed");

if(l.requestCanTransition("completed","pending"))
  throw Error("Terminal protection failed");

if(l.orderCanTransition("completed","pending"))
  throw Error("Order terminal protection failed");

console.log("✓ lifecycle");
console.log("✓ persistence");
console.log("✓ API");
console.log("✓ realtime");
console.log("✓ terminal protection");
NODE

echo
echo "=== STEP 29 COMPLETE ==="
echo "✓ RELEASE GATE PASSED"
echo "✓ No persistent data modified"
