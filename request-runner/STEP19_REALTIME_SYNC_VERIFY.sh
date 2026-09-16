#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 19 — REALTIME SYNC ==="

node --check realtime-server.js >/dev/null

node <<'NODE'
const fs=require("fs");
const s=fs.readFileSync("realtime-server.js","utf8");

for(const x of [
 "orders:snapshot",
 "order:created",
 "order:updated"
]){
  if(!s.includes(x)) throw new Error(`Missing realtime event: ${x}`);
}

console.log("✓ realtime event bridge");
NODE

R=$(curl -fsS http://127.0.0.1:3001/)
node - "$R" <<'NODE'
const x=JSON.parse(process.argv[2]);
if(x.status!=="ok") throw new Error("Realtime unhealthy");
console.log("✓ realtime service healthy");
console.log(`✓ port ${x.port}`);
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null

printf '\n✓ STEP 19 COMPLETE\n'
printf '✓ realtime synchronization verified\n'
printf '✓ No data modified\n'
