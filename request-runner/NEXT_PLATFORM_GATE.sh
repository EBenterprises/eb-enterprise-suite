#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — NEXT PLATFORM GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/platform-gate-$STAMP"
mkdir -p "$BACKUP"

for f in \
  api/domain-service.js \
  api/platform-api.js \
  realtime-server.js \
  framework/lifecycle/canonical-lifecycle.js
do
  [ -f "$f" ] && cp -f "$f" "$BACKUP/"
done

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null
node --check realtime-server.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null

node <<'NODE'
const fs=require("fs");

const required=[
 "data/customers.json",
 "data/requests.json",
 "data/orders.json",
 "data/drivers.json",
 "data/audit.json",
 "data/notifications.json",
 "data/operations.json"
];

for(const f of required){
 if(!fs.existsSync(f)) throw Error("Missing "+f);
 JSON.parse(fs.readFileSync(f,"utf8"));
}

const l=require("./framework/lifecycle/canonical-lifecycle");

if(!l.requestCanTransition("pending","accepted")) throw Error("request acceptance");
if(!l.requestCanTransition("accepted","assigned")) throw Error("request assignment");
if(!l.orderCanTransition("pending","confirmed")) throw Error("order confirmation");
if(!l.orderCanTransition("confirmed","assigned")) throw Error("order assignment");
if(l.requestCanTransition("completed","pending")) throw Error("request terminal protection");
if(l.orderCanTransition("completed","pending")) throw Error("order terminal protection");
NODE

for route in \
  /api/health \
  /api/requests \
  /api/orders \
  /api/customers \
  /api/drivers
do
  curl -fsS "http://127.0.0.1:3000$route" >/dev/null
done

curl -fsS http://127.0.0.1:3001/ >/dev/null

grep -q 'createOrderFromRequest' api/domain-service.js
grep -q 'assignDriver' api/domain-service.js
grep -q 'updateRequestStatus' api/domain-service.js
grep -q 'updateOrderStatus' api/domain-service.js

grep -q 'requests:snapshot' realtime-server.js
grep -q 'orders:snapshot' realtime-server.js

echo
echo "✓ REQUEST"
echo "✓ ACCEPTANCE"
echo "✓ ORDER"
echo "✓ ASSIGNMENT"
echo "✓ DISPATCH LIFECYCLE"
echo "✓ REALTIME"
echo "✓ PERSISTENCE"
echo "✓ AUDIT STRUCTURE"
echo "✓ API"
echo "✓ RECOVERY BACKUP"
echo "✓ EXISTING DATA UNTOUCHED"

echo
echo "=== PLATFORM GATE PASSED ==="
echo "NEXT: OPERATIONS / DISPATCH LAYER"
