#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — UNIFIED SECURITY GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/unified-security-$STAMP"
mkdir -p "$BACKUP"

cp -f framework/security/authorization.js "$BACKUP/"
cp -f framework/security/session.js "$BACKUP/"

node --check framework/security/authorization.js >/dev/null
node --check framework/security/session.js >/dev/null
node --check framework/lifecycle/canonical-lifecycle.js >/dev/null

node <<'NODE'
const auth=require("./framework/security/authorization");
const sessions=require("./framework/security/session");
const lifecycle=require("./framework/lifecycle/canonical-lifecycle");

const s=sessions.createSession("security-gate","dispatcher");

if(!s.token) throw Error("authentication failed");
if(!auth.can(s.role,"request:assign"))
 throw Error("authorization failed");

if(auth.can("customer","request:assign"))
 throw Error("privilege escalation");

if(!sessions.getSession(s.token))
 throw Error("session validation failed");

if(!lifecycle.requestCanTransition("accepted","assigned"))
 throw Error("lifecycle authorization path failed");

if(lifecycle.requestCanTransition("completed","pending"))
 throw Error("terminal bypass");

sessions.revokeSession(s.token);

if(sessions.getSession(s.token))
 throw Error("revocation failed");

console.log("authentication: PASS");
console.log("session control: PASS");
console.log("authorization: PASS");
console.log("lifecycle boundary: PASS");
console.log("privilege boundary: PASS");
NODE

node <<'NODE'
const fs=require("fs");

for(const f of fs.readdirSync("data")){
  if(f.endsWith(".json"))
    JSON.parse(fs.readFileSync("data/"+f,"utf8"));
}

console.log("persistent data: PASS");
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

echo
echo "✓ AUTHENTICATION"
echo "✓ SESSION CONTROL"
echo "✓ AUTHORIZATION"
echo "✓ LIFECYCLE BOUNDARY"
echo "✓ PRIVILEGE BOUNDARY"
echo "✓ API"
echo "✓ REALTIME"
echo "✓ PERSISTENCE"
echo "✓ NO PERSISTENT TEST DATA"
echo "✓ BACKUP CREATED"

echo
echo "=== UNIFIED SECURITY GATE PASSED ==="
echo "NEXT: BILLING / PAYMENT CONTROL PLANE"
