#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEPS 35–40 — PRODUCT EXPANSION ==="

# 35 — API surface verification
echo "[35] API SURFACE"
for p in requests orders customers drivers health; do
  curl -fsS "http://127.0.0.1:3000/api/$p" >/dev/null
done
echo "✓ API routes"

# 36 — Source integrity
echo "[36] SOURCE"
node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js
node --check realtime-server.js
echo "✓ source integrity"

# 37 — Persistence integrity
echo "[37] PERSISTENCE"
node <<'NODE'
const fs=require("fs");
for(const f of fs.readdirSync("data").filter(x=>x.endsWith(".json")))
  JSON.parse(fs.readFileSync("data/"+f,"utf8"));
console.log("✓ JSON persistence valid");
NODE

# 38 — Lifecycle integrity
echo "[38] LIFECYCLE"
node <<'NODE'
const l=require("./framework/lifecycle/canonical-lifecycle");
const r=[
["pending","accepted"],
["accepted","assigned"],
["assigned","en_route"],
["en_route","arrived"],
["arrived","picked_up"],
["picked_up","completed"]
];
const o=[
["pending","confirmed"],
["confirmed","assigned"],
["assigned","en_route"],
["en_route","arrived"],
["arrived","picked_up"],
["picked_up","completed"]
];
for(const x of r) if(!l.requestCanTransition(...x)) throw Error("request lifecycle");
for(const x of o) if(!l.orderCanTransition(...x)) throw Error("order lifecycle");
if(l.requestCanTransition("completed","pending")) throw Error("request terminal");
if(l.orderCanTransition("completed","pending")) throw Error("order terminal");
console.log("✓ lifecycle integrity");
NODE

# 39 — Runtime
echo "[39] RUNTIME"
curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null
echo "✓ API + realtime"

# 40 — Product surfaces
echo "[40] PRODUCT SURFACES"
for p in requests orders drivers ops; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000/$p")
  test "$code" = "200"
done
echo "✓ Requests"
echo "✓ Orders"
echo "✓ Drivers"
echo "✓ Operations"

echo
echo "=== STEPS 35–40 COMPLETE ==="
echo "✓ ALL PASSED"
echo "✓ NO PERSISTENT TEST DATA CREATED"
echo "✓ EXISTING DATA UNTOUCHED"
