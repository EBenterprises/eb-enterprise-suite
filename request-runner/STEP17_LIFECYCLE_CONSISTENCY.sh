#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 17 — LIFECYCLE CONSISTENCY ==="

node --check api/domain-service.js >/dev/null
node --check api/platform-api.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null

node <<'NODE'
const l=require("./framework/lifecycle/canonical-lifecycle");

const request=[
 ["pending","accepted"],
 ["accepted","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
];

const order=[
 ["pending","confirmed"],
 ["confirmed","assigned"],
 ["assigned","en_route"],
 ["en_route","arrived"],
 ["arrived","picked_up"],
 ["picked_up","completed"]
];

for(const [a,b] of request) l.assertRequestTransition(a,b);
for(const [a,b] of order) l.assertOrderTransition(a,b);

for(const [a,b] of [
 ["completed","pending"],
 ["cancelled","pending"]
]){
 try {
   l.assertRequestTransition(a,b);
   throw new Error(`Invalid transition allowed: ${a} -> ${b}`);
 } catch(e) {
   if(e.message.startsWith("Invalid transition allowed"))
     throw e;
 }
}

console.log("✓ request lifecycle");
console.log("✓ order lifecycle");
console.log("✓ terminal protection");
console.log("✓ canonical consistency");
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

printf '\n✓ STEP 17 COMPLETE\n'
printf '✓ API healthy\n'
printf '✓ realtime healthy\n'
printf '✓ No data modified\n'
