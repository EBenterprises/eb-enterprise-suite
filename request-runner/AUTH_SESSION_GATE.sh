#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — AUTH / SESSION GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/auth-session-$STAMP"
mkdir -p "$BACKUP"

mkdir -p framework/security

cat > framework/security/session.js <<'JS'
"use strict";

const crypto = require("crypto");

const sessions = new Map();

function createSession(subject, role = "customer") {
    if (!subject) {
        throw new Error("Session subject required");
    }

    const token = crypto.randomBytes(32).toString("hex");

    const session = {
        token,
        subject,
        role,
        createdAt: new Date().toISOString(),
        lastSeenAt: new Date().toISOString()
    };

    sessions.set(token, session);

    return session;
}

function getSession(token) {
    if (!token) return null;

    const session = sessions.get(token);

    if (!session) return null;

    session.lastSeenAt = new Date().toISOString();

    return session;
}

function revokeSession(token) {
    return sessions.delete(token);
}

function count() {
    return sessions.size;
}

module.exports = {
    createSession,
    getSession,
    revokeSession,
    count
};
JS

node --check framework/security/session.js >/dev/null

node <<'NODE'
const s=require("./framework/security/session");

const session=s.createSession("verification-subject","customer");

if(!session.token)
 throw Error("session token missing");

if(s.getSession(session.token)?.subject!=="verification-subject")
 throw Error("session lookup failed");

if(s.getSession(session.token)?.role!=="customer")
 throw Error("session role failed");

if(!s.revokeSession(session.token))
 throw Error("session revoke failed");

if(s.getSession(session.token)!==null)
 throw Error("revoked session still valid");

console.log("session creation: PASS");
console.log("session lookup: PASS");
console.log("session revocation: PASS");
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
echo "✓ SESSION CREATION"
echo "✓ SESSION VALIDATION"
echo "✓ SESSION REVOCATION"
echo "✓ ROLE CARRIED BY SESSION"
echo "✓ PERSISTENCE"
echo "✓ API"
echo "✓ REALTIME"
echo "✓ NO PERSISTENT TEST DATA"
echo
echo "=== AUTH / SESSION GATE PASSED ==="
echo "NEXT: UNIFIED SECURITY GATE"
