#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — CONTROL PLANE GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/control-plane-$STAMP"
mkdir -p "$BACKUP"

for f in api/domain-service.js api/platform-api.js realtime-server.js; do
  [ -f "$f" ] && cp -f "$f" "$BACKUP/"
done

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null
node --check realtime-server.js >/dev/null

node <<'NODE'
const fs=require("fs");

const domains=[
 "customers",
 "requests",
 "orders",
 "drivers",
 "locations",
 "scheduling",
 "payments",
 "notifications",
 "operations",
 "administration"
];

for(const d of domains){
 const f=`data/${d}.json`;
 if(!fs.existsSync(f)) throw Error(`Missing ${f}`);
 JSON.parse(fs.readFileSync(f,"utf8"));
}

const l=require("./framework/lifecycle/canonical-lifecycle");

const requestPath=[
 ["pending","accepted"],
 ["accepted","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
];

const orderPath=[
 ["pending","confirmed"],
 ["confirmed","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
];

for(const [a,b] of requestPath)
 if(!l.requestCanTransition(a,b)) throw Error(`request ${a}->${b}`);

for(const [a,b] of orderPath)
 if(!l.orderCanTransition(a,b)) throw Error(`order ${a}->${b}`);

console.log("domain persistence: PASS");
console.log("request lifecycle: PASS");
console.log("order lifecycle: PASS");
NODE

for route in \
 /api/health \
 /api/customers \
 /api/requests \
 /api/orders \
 /api/drivers
do
 curl -fsS "http://127.0.0.1:3000$route" >/dev/null
done

curl -fsS http://127.0.0.1:3001/ >/dev/null

grep -q 'createCustomer' api/domain-service.js
grep -q 'createRequest' api/domain-service.js
grep -q 'createOrderFromRequest' api/domain-service.js
grep -q 'assignDriver' api/domain-service.js
grep -q 'dispatchRequest' api/domain-service.js

grep -q 'requests:snapshot' realtime-server.js
grep -q 'orders:snapshot' realtime-server.js

echo
echo "✓ CUSTOMER CONTROL"
echo "✓ REQUEST CONTROL"
echo "✓ ORDER CONTROL"
echo "✓ DRIVER CONTROL"
echo "✓ DISPATCH CONTROL"
echo "✓ LIFECYCLE CONTROL"
echo "✓ REALTIME CONTROL"
echo "✓ PERSISTENCE CONTROL"
echo "✓ API CONTROL"
echo "✓ BACKUP CREATED"
echo "✓ NO TEST DATA CREATED"

echo
echo "=== CONTROL PLANE GATE PASSED ==="
echo "NEXT: PLATFORM OBSERVABILITY + AUDIT"
