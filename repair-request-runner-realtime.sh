#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "=== Request Runner® — REALTIME SERVER REPAIR ==="

# Stop the currently running Next.js process
pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true

# Restore the custom server as the npm dev entrypoint.
# Socket.IO is attached to this HTTP server.
node - <<'NODE'
const fs = require("fs");

const p = "package.json";
const j = JSON.parse(fs.readFileSync(p, "utf8"));

j.scripts = j.scripts || {};
j.scripts.dev = "node server.js";

fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n");
NODE

# Ensure the custom Next server explicitly disables Turbopack.
if grep -q 'const app = next({ dev });' server.js; then
    sed -i 's/const app = next({ dev });/const app = next({ dev, turbopack: false });/' server.js
fi

# Verify Socket.IO dependency exists
if ! node -e "require.resolve('socket.io')" >/dev/null 2>&1; then
    echo "Installing Socket.IO..."
    npm install socket.io socket.io-client
fi

echo
echo "=== CONFIGURATION ==="
grep -n "const app = next" server.js
grep -n '"dev"' package.json
node -e "console.log('Socket.IO:', require('socket.io/package.json').version)"

echo
echo "=== STARTING REALTIME SERVER ==="
echo
echo "Customer:   http://127.0.0.1:3000/request"
echo "Operations: http://127.0.0.1:3000/ops"
echo
echo "LAN address:"
echo "http://192.168.1.188:3000"
echo
echo "Socket.IO: ENABLED"
echo

exec npm run dev
