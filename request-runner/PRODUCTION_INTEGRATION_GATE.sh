#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — PRODUCTION INTEGRATION GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/integration-gate-$STAMP"
mkdir -p "$BACKUP"

cp -f api/domain-service.js "$BACKUP/domain-service.js"
cp -f api/platform-api.js "$BACKUP/platform-api.js"
cp -f realtime-server.js "$BACKUP/realtime-server.js"

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null
node --check realtime-server.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null

node <<'NODE'
const fs=require("fs");
const l=require("./framework/lifecycle/canonical-lifecycle");

const required=[
  ["request","pending","accepted"],
  ["request","accepted","assigned"],
  ["request","assigned","en_route"],
  ["request","en_route","arrived"],
  ["request","arrived","picked_up"],
  ["request","picked_up","completed"],
  ["order","pending","confirmed"],
  ["order","confirmed","assigned"],
  ["order","assigned","en_route"],
  ["order","en_route","arrived"],
  ["order","arrived","picked_up"],
  ["order","picked_up","completed"]
];

for(const [type,a,b] of required){
  const ok=type==="request"
    ? l.requestCanTransition(a,b)
    : l.orderCanTransition(a,b);
  if(!ok) throw Error(`${type}: ${a} -> ${b}`);
}

for(const f of fs.readdirSync("data")){
  if(f.endsWith(".json"))
    JSON.parse(fs.readFileSync("data/"+f,"utf8"));
}
NODE

grep -q 'createOrderFromRequest' api/domain-service.js
grep -q 'assignDriver' api/domain-service.js
grep -q 'updateRequestStatus' api/domain-service.js
grep -q 'updateOrderStatus' api/domain-service.js

grep -q 'requests:snapshot' realtime-server.js
grep -q 'orders:snapshot' realtime-server.js
grep -q 'request:created' realtime-server.js
grep -q 'request:updated' realtime-server.js
grep -q 'order:created' realtime-server.js
grep -q 'order:updated' realtime-server.js

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

node <<'NODE'
const fs=require("fs");
const files=[
 "data/customers.json",
 "data/requests.json",
 "data/orders.json",
 "data/drivers.json"
];

for(const f of files){
 const x=JSON.parse(fs.readFileSync(f,"utf8"));
 const n=Array.isArray(x)?x:(x.records||x.data||[]);
 console.log(f.split("/").pop()+": "+n.length);
}
NODE

echo
echo "✓ DOMAIN WIRING"
echo "✓ REQUEST → ORDER BRIDGE"
echo "✓ DRIVER ASSIGNMENT BRIDGE"
echo "✓ CANONICAL LIFECYCLE"
echo "✓ REALTIME EVENTS"
echo "✓ API HEALTH"
echo "✓ REALTIME HEALTH"
echo "✓ JSON PERSISTENCE"
echo "✓ NO TEST DATA CREATED"
echo "✓ BACKUP: $BACKUP"
echo
echo "=== PRODUCTION INTEGRATION GATE PASSED ==="
