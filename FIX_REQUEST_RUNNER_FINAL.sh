#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"

echo "================================================"
echo " Request Runner® — FINAL ANDROID REPAIR"
echo "================================================"

if [ ! -d "$APP" ]; then
    echo "ERROR: $APP does not exist."
    exit 1
fi

cd "$APP"

echo
echo "[1/9] Stopping old Request Runner processes..."

# Only target known application processes.
pkill -f "$APP/realtime-server.js" 2>/dev/null || true
pkill -f "next dev --webpack" 2>/dev/null || true
pkill -f "$APP/server.js" 2>/dev/null || true

sleep 1

echo
echo "[2/9] Verifying Node/npm..."

command -v node >/dev/null || {
    echo "Installing Node.js..."
    pkg install nodejs-lts -y
}

command -v npm >/dev/null || {
    echo "ERROR: npm unavailable."
    exit 1
}

echo "Node: $(node --version)"
echo "NPM:  $(npm --version)"

echo
echo "[3/9] Creating protected backup..."

BACKUP="$APP/.repair-backup-final-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp -f package.json "$BACKUP/package.json"

[ -f server.js ] && cp -f server.js "$BACKUP/server.js"
[ -f app/request/page.js ] && cp -f app/request/page.js "$BACKUP/request-page.js"
[ -f app/ops/page.js ] && cp -f app/ops/page.js "$BACKUP/ops-page.js"
[ -f app/page.js ] && cp -f app/page.js "$BACKUP/home-page.js"

echo "Backup created:"
echo "$BACKUP"

echo
echo "[4/9] Installing/verifying dependencies..."

npm install

if ! node -e "require.resolve('socket.io')" >/dev/null 2>&1; then
    npm install socket.io socket.io-client
fi

echo
echo "[5/9] Configuring Next.js for Android ARM64..."

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts = pkg.scripts || {};

/*
 * Android ARM64 cannot use Next.js Turbopack native bindings.
 * Webpack is the compatible development backend.
 */
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(
    file,
    JSON.stringify(pkg, null, 2) + "\n"
);

console.log("dev =", pkg.scripts.dev);
NODE

echo
echo "[6/9] Creating standalone realtime server on port 3001..."

cat > realtime-server.js <<'NODE'
const http = require("http");
const { Server } = require("socket.io");

const PORT = Number(process.env.REALTIME_PORT || 3001);

const httpServer = http.createServer((req, res) => {
    if (req.url === "/" || req.url === "/health") {
        res.writeHead(200, {
            "Content-Type": "application/json",
            "Cache-Control": "no-store",
            "Access-Control-Allow-Origin": "*"
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
    console.log(`[Socket.IO] Connected ${socket.id}`);

    socket.emit("request-runner:connected", {
        socketId: socket.id,
        timestamp: new Date().toISOString()
    });

    socket.on("request-runner:join", (room) => {
        if (
            typeof room === "string" &&
            room.length > 0 &&
            room.length < 200
        ) {
            socket.join(room);
            console.log(`[Socket.IO] ${socket.id} joined ${room}`);
        }
    });

    socket.on("request-runner:event", (payload) => {
        io.emit("request-runner:event", payload);
    });

    socket.on("disconnect", (reason) => {
        console.log(
            `[Socket.IO] Disconnected ${socket.id}: ${reason}`
        );
    });
});

httpServer.listen(PORT, "0.0.0.0", () => {
    console.log("");
    console.log("===============================================");
    console.log(" Request Runner® Realtime");
    console.log("===============================================");
    console.log(` Socket.IO : http://127.0.0.1:${PORT}`);
    console.log(` Health    : http://127.0.0.1:${PORT}/health`);
    console.log("===============================================");
    console.log("");
});

function shutdown() {
    console.log("");
    console.log("Stopping realtime server...");
    io.close();
    httpServer.close(() => process.exit(0));
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
NODE

chmod +x realtime-server.js

echo
echo "[7/9] Patching frontend Socket.IO endpoint..."

# Back up frontend files already done above.
# Replace common localhost:3000 Socket.IO references with :3001.
# Do not alter unrelated application URLs.

if [ -f app/request/page.js ]; then
    sed -i \
        -e 's#http://127\.0\.0\.1:3000/socket\.io#http://127.0.0.1:3001/socket.io#g' \
        -e 's#http://localhost:3000/socket\.io#http://localhost:3001/socket.io#g' \
        -e 's#http://192\.168\.1\.188:3000/socket\.io#http://192.168.1.188:3001/socket.io#g' \
        app/request/page.js
fi

if [ -f app/ops/page.js ]; then
    sed -i \
        -e 's#http://127\.0\.0\.1:3000/socket\.io#http://127.0.0.1:3001/socket.io#g' \
        -e 's#http://localhost:3000/socket\.io#http://localhost:3001/socket.io#g' \
        -e 's#http://192\.168\.1\.188:3000/socket\.io#http://192.168.1.188:3001/socket.io#g' \
        app/ops/page.js
fi

# If the frontend uses io("http://...:3000"), change that realtime endpoint.
if [ -f app/request/page.js ]; then
    sed -i \
        -e 's#io("http://127\.0\.0\.1:3000")#io("http://127.0.0.1:3001")#g' \
        -e 's#io("http://localhost:3000")#io("http://localhost:3001")#g' \
        -e 's#io("http://192\.168\.1\.188:3000")#io("http://192.168.1.188:3001")#g' \
        app/request/page.js
fi

if [ -f app/ops/page.js ]; then
    sed -i \
        -e 's#io("http://127\.0\.0\.1:3000")#io("http://127.0.0.1:3001")#g' \
        -e 's#io("http://localhost:3000")#io("http://localhost:3001")#g' \
        -e 's#io("http://192\.168\.1\.188:3000")#io("http://192.168.1.188:3001")#g' \
        app/ops/page.js
fi

echo
echo "[8/9] Creating unified launcher..."

cat > run-request-runner.sh <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"

cd "$APP"

echo "================================================"
echo " Request Runner®"
echo " Android ARM64 / Webpack / Socket.IO"
echo "================================================"
echo

# Clean only this application's processes.
pkill -f "$APP/realtime-server.js" 2>/dev/null || true
pkill -f "next dev --webpack" 2>/dev/null || true

sleep 1

echo "[1/2] Starting realtime server..."

node "$APP/realtime-server.js" \
    > "$APP/realtime.log" 2>&1 &

REALTIME_PID=$!

sleep 1

if ! kill -0 "$REALTIME_PID" 2>/dev/null; then
    echo
    echo "ERROR: Realtime server failed."
    echo
    cat "$APP/realtime.log"
    exit 1
fi

echo "Realtime PID: $REALTIME_PID"

echo
echo "[2/2] Starting Next.js Webpack server..."
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
echo "  http://192.168.1.188:3000"
echo

echo "================================================"
echo " Request Runner® READY"
echo "================================================"
echo

cleanup() {
    echo
    echo "Stopping Request Runner®..."
    kill "$REALTIME_PID" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

exec npx next dev --webpack
LAUNCHER

chmod +x run-request-runner.sh

echo
echo "[9/9] Final verification..."

echo
echo "package.json:"
node -e '
const p=require("./package.json");
console.log("dev =", p.scripts && p.scripts.dev);
'

echo
echo "Socket.IO:"
node -e '
console.log(require("socket.io/package.json").version);
'

echo
echo "Next:"
npx next --version

echo
echo "Realtime server syntax:"
node --check realtime-server.js

echo
echo "Launcher:"
test -x run-request-runner.sh
echo "✓ executable"

echo
echo "Application files:"
ls -lh \
    package.json \
    realtime-server.js \
    run-request-runner.sh

echo
echo "================================================"
echo " REPAIR COMPLETE"
echo "================================================"
echo
echo "Your original files were backed up to:"
echo "$BACKUP"
echo
echo "Start Request Runner® with:"
echo
echo "  bash ~/request-runner/run-request-runner.sh"
echo
echo "Customer:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "Realtime:"
echo "  http://127.0.0.1:3001/health"
echo
