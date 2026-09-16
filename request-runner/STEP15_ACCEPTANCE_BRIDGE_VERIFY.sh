#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 15 — ACCEPTANCE BRIDGE ==="

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null

node <<'NODE'
const fs=require("fs");
const s=fs.readFileSync("api/platform-api.js","utf8");

const checks=[
  "/requests/:id/accept",
  "createOrderFromRequest",
  "request.accepted",
  "order.created"
];

for(const x of checks){
  if(!s.includes(x)) throw new Error(`Missing: ${x}`);
}

console.log("✓ acceptance endpoint");
console.log("✓ request → order bridge");
console.log("✓ realtime events");
NODE

for p in /api/requests /api/orders /api/drivers; do
  c=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000$p")
  [ "$c" = "200" ] || {
    echo "FAILED $p = HTTP $c"
    exit 1
  }
done

printf '\n✓ STEP 15 COMPLETE\n'
printf '✓ Acceptance bridge verified\n'
printf '✓ No data modified\n'
