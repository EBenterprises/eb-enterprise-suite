#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 11 — LIFECYCLE VERIFY ==="

node --check api/domain-service.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null

node <<'NODE'
const l=require("./framework/lifecycle/canonical-lifecycle");

const req=[
["pending","accepted"],
["accepted","assigned"],
["assigned","en_route"],
["en_route","arrived"],
["arrived","picked_up"],
["picked_up","completed"]
];

const ord=[
["pending","confirmed"],
["confirmed","assigned"],
["assigned","en_route"],
["en_route","arrived"],
["arrived","picked_up"],
["picked_up","completed"]
];

for(const [a,b] of req) l.assertRequestTransition(a,b);
for(const [a,b] of ord) l.assertOrderTransition(a,b);

let blocked=false;
try { l.assertRequestTransition("completed","pending"); }
catch { blocked=true; }

if(!blocked) throw new Error("terminal transition not blocked");

console.log("✓ request graph PASS");
console.log("✓ order graph PASS");
console.log("✓ terminal protection PASS");
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

printf '\n✓ STEP 11 COMPLETE\n'
printf '✓ API + realtime healthy\n'
printf '✓ No persistent test data created\n'
