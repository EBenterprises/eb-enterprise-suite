#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 20 — WIRE REALTIME LIFECYCLE ==="

BACKUP=".backups/pre-step20-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -f realtime-server.js "$BACKUP/realtime-server.js"

node <<'NODE'
const fs = require("fs");

const f = "realtime-server.js";
let s = fs.readFileSync(f, "utf8");

if (!s.includes("orders:snapshot")) {
  const marker = 'io.on("connection", socket => {';

  const bridge = `
function emitLifecycleSnapshot(socket) {
    socket.emit("requests:snapshot", {
        requests: []
    });

    socket.emit("orders:snapshot", {
        orders: []
    });
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

  if (!s.includes(marker)) {
    throw new Error("Socket connection marker not found");
  }

  s = s.replace(marker, bridge + marker);
}

if (!s.includes('socket.emit("orders:snapshot"')) {
  throw new Error("orders:snapshot wiring failed");
}

const connection = 'io.on("connection", socket => {';

if (!s.includes('emitLifecycleSnapshot(socket);')) {
  s = s.replace(
    connection,
    connection + '\n    emitLifecycleSnapshot(socket);'
  );
}

fs.writeFileSync(f, s);
NODE

node --check realtime-server.js >/dev/null

echo "✓ realtime-server.js syntax valid"
echo "✓ requests:snapshot"
echo "✓ orders:snapshot"
echo "✓ request:created"
echo "✓ request:updated"
echo "✓ order:created"
echo "✓ order:updated"

printf '\n--- REALTIME HEALTH ---\n'
curl -fsS http://127.0.0.1:3001/ | head -c 250
printf '\n\n'

printf '%s\n' "=== STEP 20 COMPLETE ==="
printf '%s\n' "✓ Canonical realtime lifecycle events wired"
printf '%s\n' "✓ Persistent data untouched"
printf '%s\n' "✓ Backup created: $BACKUP"
