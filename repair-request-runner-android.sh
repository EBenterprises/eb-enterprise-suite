#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "================================================"
echo " Request Runner® — Android/ARM64 Final Repair"
echo "================================================"
echo

# -------------------------------------------------
# Stop previous Request Runner processes
# -------------------------------------------------
echo "[1/8] Stopping previous servers..."

pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "request-runner-realtime" 2>/dev/null || true

sleep 1

# -------------------------------------------------
# Verify dependencies
# -------------------------------------------------
echo "[2/8] Checking dependencies..."

if ! command -v node >/dev/null 2>&1; then
    echo "Installing Node.js..."
    pkg install nodejs-lts -y
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: npm is unavailable."
    exit 1
fi

npm install

# -------------------------------------------------
# Socket.IO
# -------------------------------------------------
echo "[3/8] Checking Socket.IO..."

if ! node -e "require.resolve('socket.io')" >/dev/null 2>&1; then
    npm install socket.io socket.io-client
fi

# -------------------------------------------------
# Backup application files before modification
# -------------------------------------------------
echo "[4/8] Creating safety backup..."

BACKUP="$APP/.repair-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp -f package.json "$BACKUP/package.json"
[ -f server.js ] && cp -f server.js "$BACKUP/server.js"
[ -f app/request/page.js ] && cp -f app/request/page.js "$BACKUP/request-page.js"
[ -f app/ops/page.js ] && cp -f app/ops/page.js "$BACKUP/ops-page.js"

echo "Backup: $BACKUP"

# -------------------------------------------------
# Configure Next to ALWAYS use Webpack
# -------------------------------------------------
echo "[5/8] Configuring Next.js for Android..."

node <<'NODE'
const fs = require("fs");

const p = "package.json";
const j = JSON.parse(fs.readFileSync(p, "utf8"));

j.scripts = j.scripts || {};

/*
 * IMPORTANT:
 * Do NOT launch Next through the custom server.
 *
 * Next 16 on Android/ARM64 requires:
 *
 *     next dev --webpack
 *
 * for this environment.
 */
j.scripts.dev = "next dev --webpack";
j.scripts.dev: j.scripts.dev;

fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n");
NODE

# Remove accidental invalid duplicate property if parser accepted it
node <<'NODE'
const fs = require("fs");
const p = "package.json";
const j = JSON.parse(fs.readFileSync(p, "utf8"));
j.scripts.dev = "next dev --webpack";
fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n");
NODE

# -------------------------------------------------
# Create standalone Socket.IO realtime server
# -------------------------------------------------
echo "[6/8] Creating standalone realtime server..."

cat > realtime-server.js <<'NODE'
const http = require("http");
const { Server } = require("socket.io");

const PORT = Number(process.env.REALTIME_PORT || 3001);

const httpServer = http.createServer((req, res) => {
    if (req.url === "/health" || req.url === "/") {
        res.writeHead(200, {
            "Content-Type": "application/json",
            "Cache-Control": "no-store"
        });

        res.end(JSON.stringify({
            service: "Request Runner® Realtime",
            status: "ok",
            port: PORT,
            timestamp: new Date().toISOString()
        }));

        return;
    }

    res.writeHead(404);
    res.end("Not Found");
});

const io = new Server(httpServer, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

io.on("connection", (socket) => {
    console.log(`[Socket.IO] Connected: ${socket.id}`);

    socket.emit("request-runner:connected", {
        socketId: socket.id,
        timestamp: new Date().toISOString()
    });

    socket.on("request-runner:join", (room) => {
        if (typeof room === "string" && room.length > 0) {
            socket.join(room);
            console.log(`[Socket.IO] ${socket.id} joined ${room}`);
        }
    });

    socket.on("request-runner:event", (payload) => {
        io.emit("request-runner:event", payload);
    });

    socket.on("disconnect", (reason) => {
        console.log(`[Socket.IO] Disconnected: ${socket.id} (${reason})`);
    });
});

httpServer.listen(PORT, "0.0.0.0", () => {
    console.log("");
    console.log("===============================================");
    console.log(" Request Runner® Realtime Server");
    console.log("===============================================");
    console.log(` Socket.IO: http://127.0.0.1:${PORT}`);
    console.log(` Health:    http://127.0.0.1:${PORT}/health`);
    console.log("===============================================");
    console.log("");
});

process.on("SIGINT", () => {
    console.log("\nStopping realtime server...");
    io.close();
    httpServer.close(() => process.exit(0));
});

process.on("SIGTERM", () => {
    io.close();
    httpServer.close(() => process.exit(0));
});
NODE

# -------------------------------------------------
# Create unified launcher
# -------------------------------------------------
echo "[7/8] Creating unified launcher..."

cat > run-request-runner.sh <<'NODE'
#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "==============================================="
echo " Request Runner®"
echo " Android/ARM64 Webpack + Socket.IO"
echo "==============================================="
echo

# Cleanup old processes
pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "realtime-server.js" 2>/dev/null || true

sleep 1

# Start Socket.IO
echo "[Realtime] Starting Socket.IO on :3001..."

node realtime-server.js > "$APP/realtime.log" 2>&1 &
REALTIME_PID=$!

sleep 1

if ! kill -0 "$REALTIME_PID" 2>/dev/null; then
    echo "ERROR: Realtime server failed."
    cat "$APP/realtime.log"
    exit 1
fi

echo "[Realtime] PID: $REALTIME_PID"
echo "[Realtime] http://127.0.0.1:3001"

# Cleanup when this launcher exits
cleanup() {
    echo
    echo "Stopping Request Runner®..."
    kill "$REALTIME_PID" 2>/dev/null || true
    pkill -f "next dev" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo
echo "[Next.js] Starting Webpack development server..."
echo
echo "Customer:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "LAN:"
echo "  http://192.168.1.188:3000"
echo
echo "Realtime:"
echo "  http://192.168.1.188:3001"
echo
echo "==============================================="
echo

# THIS is the critical Android fix.
exec npx next dev --webpack
NODE

chmod +x run-request-runner.sh
chmod +x realtime-server.js

# -------------------------------------------------
# Verify configuration
# -------------------------------------------------
echo "[8/8] Verifying installation..."

echo
echo "Node:"
node --version

echo
echo "NPM:"
npm --version

echo
echo "Next:"
npx next --version

echo
echo "Socket.IO:"
node -e "console.log(require('socket.io/package.json').version)"

echo
echo "package.json dev script:"
node -e "console.log(require('./package.json').scripts.dev)"

echo
echo "Files:"
ls -lh \
    package.json \
    realtime-server.js \
    run-request-runner.sh

echo
echo "==============================================="
echo " REPAIR COMPLETE"
echo "==============================================="
echo
echo "IMPORTANT:"
echo "The old server.js is no longer used to launch Next."
echo
echo "Start everything with:"
echo
echo "  bash ~/request-runner/run-request-runner.sh"
echo
echo "==============================================="
