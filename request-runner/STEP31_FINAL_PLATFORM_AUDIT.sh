#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 31 — FINAL PLATFORM AUDIT ==="

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
const l=require("./framework/lifecycle/canonical-lifecycle");

for(const f of fs.readdirSync("data").filter(f=>f.endsWith(".json")))
  JSON.parse(fs.readFileSync("data/"+f,"utf8"));

const checks=[
  ["request pending→accepted",l.requestCanTransition("pending","accepted")],
  ["request accepted→assigned",l.requestCanTransition("accepted","assigned")],
  ["request assigned→en_route",l.requestCanTransition("assigned","en_route")],
  ["request en_route→arrived",l.requestCanTransition("en_route","arrived")],
  ["request arrived→picked_up",l.requestCanTransition("arrived","picked_up")],
  ["request picked_up→completed",l.requestCanTransition("picked_up","completed")],
  ["order pending→confirmed",l.orderCanTransition("pending","confirmed")],
  ["order confirmed→assigned",l.orderCanTransition("confirmed","assigned")],
  ["order assigned→en_route",l.orderCanTransition("assigned","en_route")],
  ["order en_route→arrived",l.orderCanTransition("en_route","arrived")],
  ["order arrived→picked_up",l.orderCanTransition("arrived","picked_up")],
  ["order picked_up→completed",l.orderCanTransition("picked_up","completed")]
];

for(const [name,ok] of checks) {
  if(!ok) throw Error(name+" FAILED");
}

if(l.requestCanTransition("completed","pending"))
  throw Error("request terminal protection FAILED");

if(l.orderCanTransition("completed","pending"))
  throw Error("order terminal protection FAILED");

console.log("✓ persistence");
console.log("✓ lifecycle");
console.log("✓ terminal protection");
console.log("✓ API");
console.log("✓ realtime");
console.log("✓ FINAL AUDIT");
NODE

echo
echo "=== STEP 31 COMPLETE ==="
echo "✓ FINAL PLATFORM AUDIT PASSED"
echo "✓ No data modified"
