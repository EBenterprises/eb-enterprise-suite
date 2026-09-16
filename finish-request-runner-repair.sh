#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "==============================================="
echo " Request Runner® — Final Android Repair"
echo "==============================================="

# Stop old instances
pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "realtime-server.js" 2>/dev/null || true
sleep 1

# ------------------------------------------------
# Backup current configuration
# ------------------------------------------------
BACKUP="$APP/.repair-backup-final-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp -f package.json "$BACKUP/package.json"
[ -f server.js ] && cp -f server.js "$BACKUP/server.js"
[ -f app/request/page.js ] && cp -f app/request/page.js "$BACKUP/request-page.js"
[ -f app/ops/page.js ] && cp -f app/ops/page.js "$BACKUP/ops-page.js"

echo "Backup created:"
echo "$BACKUP"

# ------------------------------------------------
# Ensure dependencies
# ------------------------------------------------
command -v node >/dev/null 2>&1 || pkg install nodejs-lts -y
command -v npm >/dev/null 2>&1 || {
    echo "ERROR: npm unavailable"
    exit 1
}

if ! node -e "require.resolve('socket.io')" >/dev/null 2>&1; then
    npm install socket.io socket.io-client
fi

# ------------------------------------------------
# Force Next.js Webpack
# ------------------------------------------------
node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts = pkg.scripts || {};
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
NODE

# ------------------------------------------------
# Standalone Socket.IO server
# ------------------------------------------------
cat > realtime-server.js <<'NODE'
const http = require("http");
const { Server } = require("socket.io");

const PORT = Number(process.env.REALTIME_PORT || 3001);

const httpServer = http.createServer((req, res) => {
    if (req.url === "/" || req.url === "/health") {
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
    console.log("===============================================");
    console.log(" Request Runner® Realtime Server");
    console.log("===============================================");
    console.log(` Socket.IO: http://127.0.0.1:${PORT}`);
    console.log(` Health:    http://127.0.0.1:${PORT}/health`);
    console.log("===============================================");
});

function shutdown() {
    console.log("\nStopping realtime server...");
    io.close();
    httpServer.close(() => process.exit(0));
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
NODE

chmod +x realtime-server.js

# ------------------------------------------------
# Unified launcher
# ------------------------------------------------
cat > run-request-runner.sh <<'EOF2'
#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "==============================================="
echo " Request Runner®"
echo " Android/ARM64 Webpack + Socket.IO"
echo "==============================================="

pkill -f "$APP/server.js" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "realtime-server.js" 2>/dev/null || true

sleep 1

echo
echo "[1] Starting realtime server..."

node realtime-server.js > "$APP/realtime.log" 2>&1 &
REALTIME_PID=$!

sleep 1

if ! kill -0 "$REALTIME_PID" 2>/dev/null; then
    echo "ERROR: Socket.IO failed to start."
    cat "$APP/realtime.log"
    exit 1
fi

echo "Socket.IO PID: $REALTIME_PID"

cleanup() {
    echo
    echo "Stopping Request Runner®..."
    kill "$REALTIME_PID" 2>/dev/null || true
    pkill -f "next-server" 2>/dev/null || true
    pkill -f "next dev" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

echo
echo "[2] Starting Next.js with Webpack..."
echo
echo "Customer:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "Realtime:"
echo "  http://127.0.0.1:3001"
echo
echo "LAN:"
echo "  http://$(ip route 2>/dev/null | awk '/src/ {print $NF; exit}'):3000"
echo

exec npx next dev --webpack
EOF2

chmod +x run-request-runner.sh

# ------------------------------------------------
# Verification
# ------------------------------------------------
echo
echo "==============================================="
echo " VERIFICATION"
echo "==============================================="

echo "Node: $(node --version)"
echo "NPM:  $(npm --version)"
echo "Next: $(npx next --version)"

echo
echo "Dev script:"
node -e 'console.log(require("./package.json").scripts.dev)'

echo
echo "Socket.IO:"
node -e 'console.log(require("socket.io/package.json").version)'

echo
echo "Launcher:"
ls -lh run-request-runner.sh realtime-server.js

echo
echo "==============================================="
echo " REPAIR COMPLETE"
echo "==============================================="
echo
echo "Start the application with:"
echo
echo "  bash ~/request-runner/run-request-runner.sh"
echo
