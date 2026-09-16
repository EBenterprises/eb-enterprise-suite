const http = require("http");
const { Server } = require("socket.io");

const {
    eventBus
} = require("./framework/application-service");

const PORT = Number(process.env.REALTIME_PORT || 3001);

const httpServer = http.createServer((req, res) => {
    if (req.url === "/health") {
        res.writeHead(200, {
            "Content-Type": "application/json",
            "Cache-Control": "no-store"
        });

        res.end(
            JSON.stringify({
                ok: true,
                service: "realtime",
                port: PORT,
                timestamp: new Date().toISOString()
            })
        );

        return;
    }

    res.writeHead(404);
    res.end("Not Found");
});

const io = new Server(httpServer, {
    cors: {
        origin: "*"
    }
});

io.on("connection", socket => {
    socket.emit("realtime.connected", {
        socketId: socket.id,
        timestamp: new Date().toISOString()
    });

    socket.on("subscribe", channel => {
        if (typeof channel !== "string" || !channel) {
            return;
        }

        socket.join(channel);

        socket.emit("subscription.confirmed", {
            channel
        });
    });

    socket.on("unsubscribe", channel => {
        if (typeof channel !== "string" || !channel) {
            return;
        }

        socket.leave(channel);
    });

    socket.on("disconnect", reason => {
        console.log(
            `[realtime] disconnected ${socket.id}: ${reason}`
        );
    });
});

const events = [
    "entity.created",
    "entity.updated",
    "entity.deleted",

    "customers.created",
    "customers.updated",
    "customers.deleted",

    "requests.created",
    "requests.updated",
    "requests.deleted",

    "orders.created",
    "orders.updated",
    "orders.deleted",

    "drivers.created",
    "drivers.updated",
    "drivers.deleted",

    "locations.created",
    "locations.updated",
    "locations.deleted",

    "scheduling.created",
    "scheduling.updated",
    "scheduling.deleted",

    "payments.created",
    "payments.updated",
    "payments.deleted",

    "notifications.created",
    "notifications.updated",
    "notifications.deleted",

    "operations.created",
    "operations.updated",
    "operations.deleted",

    "administration.created",
    "administration.updated",
    "administration.deleted"
];

for (const event of events) {
    eventBus.subscribe(event, payload => {
        io.emit(event, payload);

        const collection =
            payload?.collection ||
            event.split(".")[0];

        if (collection) {
            io.to(collection).emit(event, payload);
        }
    });
}

httpServer.listen(PORT, "0.0.0.0", () => {
    console.log(
        `[realtime] Socket.IO® listening on 0.0.0.0:${PORT}`
    );
});
