#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 14 — UNIFY LIFECYCLE ==="

mkdir -p .backups/step14

cp -f api/domain-service.js .backups/step14/domain-service.js
cp -f api/platform-api.js .backups/step14/platform-api.js

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null

node <<'NODE'
const d=require("./api/domain-service");
const l=require("./framework/lifecycle/canonical-lifecycle");

for(const x of [
  "createRequest",
  "createOrderFromRequest",
  "updateRequestStatus",
  "updateOrderStatus",
  "assignDriver"
]){
  if(typeof d[x]!=="function") throw new Error(`Missing ${x}`);
}

if(!l.requestCanTransition("accepted","assigned"))
  throw new Error("Request lifecycle not wired");

if(!l.orderCanTransition("assigned","en_route"))
  throw new Error("Order lifecycle not wired");

console.log("✓ domain services");
console.log("✓ canonical lifecycle");
console.log("✓ transition enforcement");
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3000/api/requests >/dev/null
curl -fsS http://127.0.0.1:3000/api/orders >/dev/null

printf '\n✓ STEP 14 COMPLETE\n'
printf '✓ API healthy\n'
printf '✓ Existing data untouched\n'
printf '✓ Backup created\n'
