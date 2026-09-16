#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 30 — PRODUCTION HARDENING ==="

test -f api/domain-service.js
test -f framework/lifecycle/canonical-lifecycle.js
test -f realtime-server.js

node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js
node --check realtime-server.js

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

node <<'NODE'
const fs=require("fs");

for(const f of fs.readdirSync("data").filter(x=>x.endsWith(".json"))){
  JSON.parse(fs.readFileSync("data/"+f,"utf8"));
}

const l=require("./framework/lifecycle/canonical-lifecycle");

if(!l.requestCanTransition("accepted","assigned"))
  throw Error("request lifecycle failure");

if(!l.orderCanTransition("assigned","en_route"))
  throw Error("order lifecycle failure");

if(l.requestCanTransition("completed","pending"))
  throw Error("request terminal protection failure");

if(l.orderCanTransition("completed","pending"))
  throw Error("order terminal protection failure");

console.log("✓ source");
console.log("✓ persistence");
console.log("✓ API");
console.log("✓ realtime");
console.log("✓ lifecycle");
console.log("✓ terminal protection");
NODE

echo
echo "=== STEP 30 COMPLETE ==="
echo "✓ PRODUCTION HARDENING PASSED"
echo "✓ No data modified"
