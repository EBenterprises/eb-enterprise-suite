const http = require("http");
const { Server } = require("socket.io");

const PORT = Number(process.env.REALTIME_PORT || 3001);

const httpServer = http.createServer((req, res) => {
    if (req.url === "/health") {
        res.writeHead(200, {
            "Content-Type": "application/json"
        });

        res.end(
            JSON.stringify({
                status: "healthy",
                service: "EB Platform® Realtime®",
                port: PORT,
                timestamp: new Date().toISOString()
            })
        );

        return;
    }

    res.writeHead(200, {
        "Content-Type": "application/json"
    });

    res.end(
        JSON.stringify({
            service: "EB Platform® Realtime®",
            socketio: true,
            timestamp: new Date().toISOString()
        })
    );
});

const io = new Server(httpServer, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "PATCH", "DELETE"]
    },
    transports: ["polling", "websocket"]
});


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

io.on("connection", socket => {
    emitLifecycleSnapshot(socket);
    console.log(
        `[Realtime®] connected ${socket.id}`
    );

    socket.emit("realtime.ready", {
        socketId: socket.id,
        serverTime: new Date().toISOString()
    });

    socket.on("room.join", room => {
        if (typeof room !== "string" || !room.trim()) {
            return;
        }

        socket.join(room.trim());

        socket.emit("room.joined", {
            room: room.trim()
        });
    });

    socket.on("room.leave", room => {
        if (typeof room !== "string" || !room.trim()) {
            return;
        }

        socket.leave(room.trim());

        socket.emit("room.left", {
            room: room.trim()
        });
    });

    socket.on("client.ping", payload => {
        socket.emit("server.pong", {
            received: payload ?? null,
            timestamp: new Date().toISOString()
        });
    });

    socket.on("disconnect", reason => {
        console.log(
            `[Realtime®] disconnected ${socket.id}: ${reason}`
        );
    });
});

httpServer.listen(PORT, "0.0.0.0", () => {
    console.log(
        `[Realtime®] Socket.IO listening on 0.0.0.0:${PORT}`
    );
});

function shutdown(signal) {
    console.log(`[Realtime®] ${signal}`);

    io.close(() => {
        httpServer.close(() => {
            process.exit(0);
        });
    });
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

module.exports = {
    io,
    httpServer
};
