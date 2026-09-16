#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEPS 55–64 — INTEGRATION GATE ==="

echo "[55] APP ROUTES"
for p in requests orders drivers ops; do
  test "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:3000/$p")" = 200
done
echo "✓"

echo "[56] API ROUTES"
for p in requests orders customers drivers; do
  curl -fsS "http://127.0.0.1:3000/api/$p" >/dev/null
done
echo "✓"

echo "[57] HEALTH"
curl -fsS http://127.0.0.1:3000/api/health >/dev/null
echo "✓"

echo "[58] REALTIME"
curl -fsS http://127.0.0.1:3001/ >/dev/null
echo "✓"

echo "[59] DOMAIN"
node --check api/domain-service.js
echo "✓"

echo "[60] PLATFORM API"
node --check api/platform-api.js
echo "✓"

echo "[61] LIFECYCLE"
node --check framework/lifecycle/canonical-lifecycle.js
echo "✓"

echo "[62] SECURITY"
node --check framework/security/authorization.js
node --check framework/security/session.js
echo "✓"

echo "[63] PERSISTENCE"
node <<'NODE'
const fs=require("fs");
for(const f of fs.readdirSync("data").filter(f=>f.endsWith(".json")))
  JSON.parse(fs.readFileSync("data/"+f,"utf8"));
console.log("✓ JSON valid");
NODE

echo "[64] RELEASE GATE"
node <<'NODE'
const l=require("./framework/lifecycle/canonical-lifecycle");

if(!l.requestCanTransition("accepted","assigned"))
  throw Error("request transition failed");

if(!l.orderCanTransition("assigned","en_route"))
  throw Error("order transition failed");

if(l.requestCanTransition("completed","pending"))
  throw Error("request terminal bypass");

if(l.orderCanTransition("completed","pending"))
  throw Error("order terminal bypass");

console.log("✓ lifecycle contract");
NODE

echo
echo "=== STEPS 55–64 COMPLETE ==="
echo "✓ ALL PASSED"
echo "✓ NO DATA MODIFIED"
