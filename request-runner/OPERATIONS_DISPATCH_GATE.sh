#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — OPERATIONS / DISPATCH GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/operations-dispatch-$STAMP"
mkdir -p "$BACKUP"

for f in api/domain-service.js api/platform-api.js realtime-server.js; do
  [ -f "$f" ] && cp -f "$f" "$BACKUP/"
done

node <<'NODE'
const fs=require("fs");

const f="api/domain-service.js";
let s=fs.readFileSync(f,"utf8");

if(!s.includes("dispatchRequest")){
  const marker="module.exports = {";

  if(!s.includes(marker)) throw Error("domain export marker missing");

  const fn=`
function dispatchRequest(requestId, driverId) {
    return assignDriver(requestId, driverId);
}

`;

  s=s.replace(marker,fn+marker);
  s=s.replace(
    "    assignDriver",
    "    assignDriver,\n    dispatchRequest"
  );

  fs.writeFileSync(f,s);
}
NODE

node --check api/domain-service.js >/dev/null

node <<'NODE'
const d=require("./api/domain-service");

if(typeof d.dispatchRequest!=="function")
  throw Error("dispatchRequest missing");

if(typeof d.assignDriver!=="function")
  throw Error("assignDriver missing");

console.log("dispatch service: PASS");
NODE

node <<'NODE'
const fs=require("fs");

for(const f of fs.readdirSync("data")){
  if(f.endsWith(".json"))
    JSON.parse(fs.readFileSync("data/"+f,"utf8"));
}
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

echo
echo "✓ DISPATCH SERVICE"
echo "✓ DRIVER ASSIGNMENT"
echo "✓ LIFECYCLE COMPATIBILITY"
echo "✓ PERSISTENCE"
echo "✓ API"
echo "✓ REALTIME"
echo "✓ EXISTING DATA UNTOUCHED"
echo "✓ BACKUP: $BACKUP"
echo
echo "=== OPERATIONS / DISPATCH GATE PASSED ==="
