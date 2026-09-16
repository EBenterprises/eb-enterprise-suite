#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 12 — REQUEST/ORDER RECONCILIATION ==="

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null

node <<'NODE'
const fs=require("fs");
const s=fs.readFileSync("api/domain-service.js","utf8");

for(const x of [
  "createOrderFromRequest",
  "updateRequestStatus",
  "updateOrderStatus",
  "assignDriver"
]){
  if(!s.includes(`function ${x}`))
    throw new Error(`Missing ${x}`);
}

console.log("✓ domain lifecycle services present");
NODE

R=$(curl -fsS http://127.0.0.1:3000/api/requests)
O=$(curl -fsS http://127.0.0.1:3000/api/orders)

node - "$R" "$O" <<'NODE'
const r=JSON.parse(process.argv[2]);
const o=JSON.parse(process.argv[3]);

if(!Array.isArray(r.data)) throw new Error("requests unavailable");
if(!Array.isArray(o.data)) throw new Error("orders unavailable");

console.log(`✓ requests: ${r.data.length}`);
console.log(`✓ orders: ${o.data.length}`);

for(const x of r.data){
  if(x.orderId){
    const match=o.data.find(y=>y.id===x.orderId);
    if(!match) throw new Error(`orphan request orderId: ${x.id}`);
  }
}

console.log("✓ no orphan request→order references");
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
printf '\n✓ STEP 12 COMPLETE\n'
printf '✓ Existing data preserved\n'
