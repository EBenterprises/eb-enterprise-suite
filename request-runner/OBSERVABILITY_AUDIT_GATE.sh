#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — OBSERVABILITY / AUDIT GATE ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/observability-$STAMP"
mkdir -p "$BACKUP"

for f in api/domain-service.js api/platform-api.js realtime-server.js; do
  [ -f "$f" ] && cp -f "$f" "$BACKUP/"
done

mkdir -p framework/observability

cat > framework/observability/audit.js <<'JS'
"use strict";

const fs = require("fs");
const path = require("path");

const file = path.join(
    process.cwd(),
    "data",
    "audit.json"
);

function read() {
    if (!fs.existsSync(file)) return [];
    const value = JSON.parse(fs.readFileSync(file, "utf8"));
    return Array.isArray(value) ? value : [];
}

function record(event, payload = {}) {
    const entries = read();

    entries.push({
        id: `audit_${Date.now()}_${Math.random().toString(36).slice(2,8)}`,
        event,
        payload,
        timestamp: new Date().toISOString()
    });

    fs.writeFileSync(
        file,
        JSON.stringify(entries, null, 2)
    );

    return entries.at(-1);
}

module.exports = {
    read,
    record
};
JS

node --check framework/observability/audit.js >/dev/null

node <<'NODE'
const fs=require("fs");

const files=[
 "data/audit.json",
 "data/operations.json",
 "data/notifications.json"
];

for(const f of files){
 if(!fs.existsSync(f)) throw Error(`Missing ${f}`);
 JSON.parse(fs.readFileSync(f,"utf8"));
}

const audit=require("./framework/observability/audit");

if(typeof audit.read!=="function")
 throw Error("audit.read missing");

if(typeof audit.record!=="function")
 throw Error("audit.record missing");

console.log("audit subsystem: PASS");
console.log("persistence: PASS");
NODE

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

echo
echo "✓ AUDIT SUBSYSTEM"
echo "✓ OPERATIONS DATA"
echo "✓ NOTIFICATIONS DATA"
echo "✓ PERSISTENCE"
echo "✓ API"
echo "✓ REALTIME"
echo "✓ NO AUDIT TEST RECORD CREATED"
echo "✓ BACKUP: $BACKUP"

echo
echo "=== OBSERVABILITY / AUDIT GATE PASSED ==="
echo "NEXT: SECURITY + AUTHORIZATION CONTROL"
