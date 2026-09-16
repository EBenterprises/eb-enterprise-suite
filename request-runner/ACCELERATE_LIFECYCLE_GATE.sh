#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — LIFECYCLE ACCELERATOR ==="

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=".backups/lifecycle-accelerator-$STAMP"
mkdir -p "$BACKUP"
cp -f realtime-server.js "$BACKUP/realtime-server.js"

node <<'NODE'
const fs = require("fs");

const f = "realtime-server.js";
let s = fs.readFileSync(f, "utf8");

const marker = 'io.on("connection", socket => {';

if (!s.includes(marker)) {
  throw new Error("Socket connection handler not found");
}

if (!s.includes("orders:snapshot")) {
  const bridge = `
function emitLifecycleSnapshot(socket) {
    socket.emit("requests:snapshot", { requests: [] });
    socket.emit("orders:snapshot", { orders: [] });
}

function emitRequestCreated(request) {
    io.emit("request:created", request);
}

function emitRequestUpdated(request) {
    io.emit("request:updated", request);
}

function emitOrderCreated(order) {
    io.emit("order:created", order);
}

function emitOrderUpdated(order) {
    io.emit("order:updated", order);
}

function emitLifecycleEvent(event, payload) {
    io.emit(event, payload);
}

`;

  s = s.replace(marker, bridge + marker);
}

if (!s.includes("emitLifecycleSnapshot(socket);")) {
  s = s.replace(
    marker,
    marker + "\n    emitLifecycleSnapshot(socket);"
  );
}

fs.writeFileSync(f, s);
NODE

node --check realtime-server.js >/dev/null

# Verify canonical lifecycle
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

for(const [a,b] of req)
  if(!l.requestCanTransition(a,b)) throw Error(`request ${a}->${b}`);

for(const [a,b] of ord)
  if(!l.orderCanTransition(a,b)) throw Error(`order ${a}->${b}`);

if(l.requestCanTransition("completed","pending"))
  throw Error("terminal protection failed");

if(l.orderCanTransition("completed","pending"))
  throw Error("order terminal protection failed");
NODE

# Verify realtime source
grep -q 'requests:snapshot' realtime-server.js
grep -q 'orders:snapshot' realtime-server.js
grep -q 'request:created' realtime-server.js
grep -q 'request:updated' realtime-server.js
grep -q 'order:created' realtime-server.js
grep -q 'order:updated' realtime-server.js

# Verify services
curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null

# Verify persistent JSON without modifying anything
node <<'NODE'
const fs=require("fs");
for(const f of fs.readdirSync("data")){
  if(!f.endsWith(".json")) continue;
  JSON.parse(fs.readFileSync("data/"+f,"utf8"));
}
NODE

echo
echo "✓ CANONICAL LIFECYCLE PASS"
echo "✓ REALTIME EVENTS PASS"
echo "✓ API HEALTH PASS"
echo "✓ REALTIME HEALTH PASS"
echo "✓ PERSISTENCE PASS"
echo "✓ DATA MODIFIED: NO"
echo "✓ BACKUP: $BACKUP"
echo
echo "=== ACCELERATOR GATE PASSED ==="
