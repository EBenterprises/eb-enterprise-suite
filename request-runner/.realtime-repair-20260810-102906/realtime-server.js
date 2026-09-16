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
