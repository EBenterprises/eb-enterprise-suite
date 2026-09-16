#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — SECURITY / AUTHORIZATION GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/security-auth-$STAMP"
mkdir -p "$BACKUP"

for f in api/domain-service.js api/platform-api.js realtime-server.js; do
  [ -f "$f" ] && cp -f "$f" "$BACKUP/"
done

mkdir -p framework/security

cat > framework/security/authorization.js <<'JS'
"use strict";

const ROLES = Object.freeze([
    "customer",
    "driver",
    "dispatcher",
    "operator",
    "administrator"
]);

const PERMISSIONS = Object.freeze({
    customer: [
        "request:create",
        "request:read:self",
        "order:read:self"
    ],

    driver: [
        "request:read:assigned",
        "request:update:assigned",
        "order:read:assigned"
    ],

    dispatcher: [
        "request:read",
        "request:assign",
        "order:read",
        "order:update"
    ],

    operator: [
        "request:read",
        "order:read",
        "driver:read",
        "operations:read"
    ],

    administrator: ["*"]
});

function isRole(role) {
    return ROLES.includes(role);
}

function can(role, permission) {
    if (!isRole(role)) return false;

    const permissions = PERMISSIONS[role] || [];

    return permissions.includes("*") ||
           permissions.includes(permission);
}

function assertCan(role, permission) {
    if (!can(role, permission)) {
        throw new Error(
            `Authorization denied: ${role} -> ${permission}`
        );
    }

    return true;
}

module.exports = {
    ROLES,
    PERMISSIONS,
    isRole,
    can,
    assertCan
};
JS

node --check framework/security/authorization.js >/dev/null

node <<'NODE'
const a=require("./framework/security/authorization");

for(const role of a.ROLES){
 if(!a.isRole(role)) throw Error(`Invalid role: ${role}`);
}

if(!a.can("customer","request:create"))
 throw Error("customer request permission failed");

if(!a.can("dispatcher","request:assign"))
 throw Error("dispatcher assignment permission failed");

if(!a.can("administrator","anything"))
 throw Error("administrator wildcard failed");

if(a.can("customer","request:assign"))
 throw Error("customer privilege escalation");

if(a.can("driver","request:assign"))
 throw Error("driver privilege escalation");

console.log("roles: PASS");
console.log("permissions: PASS");
console.log("privilege boundaries: PASS");
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
echo "✓ ROLE MODEL"
echo "✓ PERMISSION MODEL"
echo "✓ PRIVILEGE BOUNDARIES"
echo "✓ PERSISTENCE"
echo "✓ API"
echo "✓ REALTIME"
echo "✓ NO TEST DATA CREATED"
echo "✓ BACKUP: $BACKUP"

echo
echo "=== SECURITY / AUTHORIZATION GATE PASSED ==="
echo "NEXT: AUTHENTICATION + SESSION CONTROL"
