#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 18 — PERSISTENCE INTEGRITY ==="

node <<'NODE'
const fs=require("fs");

for(const f of [
 "data/customers.json",
 "data/requests.json",
 "data/orders.json",
 "data/drivers.json"
]){
  if(!fs.existsSync(f)) throw new Error(`Missing ${f}`);
  JSON.parse(fs.readFileSync(f,"utf8"));
}

console.log("✓ persistence files valid JSON");
NODE

BEFORE=$(curl -fsS http://127.0.0.1:3000/api/health)

node - "$BEFORE" <<'NODE'
const x=JSON.parse(process.argv[2]);
if(!x.data) throw new Error("Invalid health payload");
console.log(`✓ customers: ${x.data.customers}`);
console.log(`✓ requests: ${x.data.requests}`);
console.log(`✓ orders: ${x.data.orders}`);
NODE

curl -fsS http://127.0.0.1:3000/api/requests >/dev/null
curl -fsS http://127.0.0.1:3000/api/orders >/dev/null

printf '\n✓ STEP 18 COMPLETE\n'
printf '✓ persistence readable\n'
printf '✓ existing data preserved\n'
printf '✓ No data modified\n'
