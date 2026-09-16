#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 16 — ASSIGNMENT BRIDGE ==="

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null

node <<'NODE'
const fs=require("fs");
const s=fs.readFileSync("api/domain-service.js","utf8");

for(const x of [
  "function assignDriver",
  "assignedDriverId",
  'status: "assigned"',
  "driverId"
]){
  if(!s.includes(x)) throw new Error(`Missing: ${x}`);
}

console.log("✓ driver assignment service");
console.log("✓ request assignment state");
console.log("✓ order driver synchronization");
NODE

c=$(curl -s -o /dev/null -w "%{http_code}" \
  http://127.0.0.1:3000/api/drivers)

[ "$c" = "200" ] || {
  echo "FAILED /api/drivers = HTTP $c"
  exit 1
}

curl -fsS http://127.0.0.1:3000/api/health >/dev/null

printf '\n✓ STEP 16 COMPLETE\n'
printf '✓ Assignment bridge verified\n'
printf '✓ No data modified\n'
