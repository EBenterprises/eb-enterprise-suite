#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.real-upgrade-backup-$STAMP"

echo
echo "=============================================================="
echo " EB PLATFORM® — MAKE EVERYTHING REAL"
echo "=============================================================="
echo
echo "Root: $ROOT"
echo "Backup: $BACKUP"
echo

mkdir -p "$BACKUP"
mkdir -p .runtime
mkdir -p data
mkdir -p api
mkdir -p realtime

backup_file() {
    local file="$1"

    if [ -f "$file" ]; then
        mkdir -p "$BACKUP/$(dirname "$file")"
        cp -p "$file" "$BACKUP/$file"
    fi
}

backup_file "framework/core/events/event-bus.js"
backup_file "realtime-server.js"
backup_file "server.js"
backup_file "EB_PLATFORM.sh"
backup_file "package.json"

echo "[1] BACKUP"
echo "--------------------------------------------------------------"
echo "✓ Existing files preserved in:"
echo "  $BACKUP"
echo

echo "[2] REAL EVENT BUS"
echo "--------------------------------------------------------------"

cat > framework/core/events/event-bus.js <<'JS'
const { EventEmitter } = require("events");

class EventBus {
    constructor() {
        this.emitter = new EventEmitter();
        this.emitter.setMaxListeners(1000);
    }

    on(event, handler) {
        if (typeof handler !== "function") {
            throw new TypeError("EventBus.on requires a function");
        }

        this.emitter.on(event, handler);

        return () => {
            this.emitter.off(event, handler);
        };
    }

    subscribe(event, handler) {
        return this.on(event, handler);
    }

    once(event, handler) {
        if (typeof handler !== "function") {
            throw new TypeError("EventBus.once requires a function");
        }

        this.emitter.once(event, handler);
    }

    emit(event, payload) {
        return this.emitter.emit(event, payload);
    }

    publish(event, payload) {
        return this.emit(event, payload);
    }

    off(event, handler) {
        return this.emitter.off(event, handler);
    }

    removeAll(event) {
        this.emitter.removeAllListeners(event);
    }

    listenerCount(event) {
        return this.emitter.listenerCount(event);
    }
}

module.exports = EventBus;
JS

node --check framework/core/events/event-bus.js
echo "✓ EventBus® real API installed"
echo

echo "[3] REAL PERSISTENCE LAYER"
echo "--------------------------------------------------------------"

cat > api/store.js <<'JS'
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const DATA_DIR = path.join(ROOT, "data");

fs.mkdirSync(DATA_DIR, { recursive: true });

function fileFor(collection) {
    return path.join(DATA_DIR, `${collection}.json`);
}

function read(collection) {
    const file = fileFor(collection);

    if (!fs.existsSync(file)) {
        return [];
    }

    try {
        const raw = fs.readFileSync(file, "utf8");

        if (!raw.trim()) {
            return [];
        }

        const value = JSON.parse(raw);

        return Array.isArray(value) ? value : [];
    } catch (error) {
        throw new Error(
            `Unable to read collection ${collection}: ${error.message}`
        );
    }
}

function write(collection, records) {
    const file = fileFor(collection);
    const temp = `${file}.${process.pid}.tmp`;

    fs.writeFileSync(
        temp,
        JSON.stringify(records, null, 2) + "\n",
        "utf8"
    );

    fs.renameSync(temp, file);

    return records;
}

function all(collection) {
    return read(collection);
}

function findById(collection, id) {
    return read(collection).find(item => String(item.id) === String(id)) || null;
}

function insert(collection, record) {
    const records = read(collection);

    records.push(record);

    write(collection, records);

    return record;
}

function update(collection, id, patch) {
    const records = read(collection);

    const index = records.findIndex(
        item => String(item.id) === String(id)
    );

    if (index === -1) {
        return null;
    }

    records[index] = {
        ...records[index],
        ...patch,
        updatedAt: new Date().toISOString()
    };

    write(collection, records);

    return records[index];
}

function remove(collection, id) {
    const records = read(collection);

    const next = records.filter(
        item => String(item.id) !== String(id)
    );

    if (next.length === records.length) {
        return false;
    }

    write(collection, next);

    return true;
}

function count(collection) {
    return read(collection).length;
}

module.exports = {
    DATA_DIR,
    all,
    findById,
    insert,
    update,
    remove,
    count
};
JS

node --check api/store.js
echo "✓ Persistent JSON datastore installed"
echo

echo "[4] REAL DOMAIN SERVICE"
echo "--------------------------------------------------------------"

cat > api/domain-service.js <<'JS'
const crypto = require("crypto");

const store = require("./store");

function id(prefix) {
    return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

function now() {
    return new Date().toISOString();
}

function createCustomer(input = {}) {
    if (!input.name || !String(input.name).trim()) {
        throw new Error("Customer name is required");
    }

    const customer = {
        id: id("cus"),
        name: String(input.name).trim(),
        phone: input.phone ? String(input.phone).trim() : null,
        email: input.email ? String(input.email).trim() : null,
        status: "active",
        createdAt: now(),
        updatedAt: now()
    };

    return store.insert("customers", customer);
}

function createRequest(input = {}) {
    if (!input.customerId) {
        throw new Error("customerId is required");
    }

    const customer = store.findById("customers", input.customerId);

    if (!customer) {
        throw new Error("Customer not found");
    }

    const request = {
        id: id("req"),
        customerId: input.customerId,
        pickup: input.pickup || null,
        destination: input.destination || null,
        notes: input.notes || "",
        status: "pending",
        assignedDriverId: null,
        orderId: null,
        createdAt: now(),
        updatedAt: now()
    };

    return store.insert("requests", request);
}

function createOrderFromRequest(request) {
    if (!request) {
        throw new Error("Request not found");
    }

    if (request.orderId) {
        return store.findById("orders", request.orderId);
    }

    const order = {
        id: id("ord"),
        requestId: request.id,
        customerId: request.customerId,
        status: "pending",
        driverId: null,
        createdAt: now(),
        updatedAt: now()
    };

    const created = store.insert("orders", order);

    store.update("requests", request.id, {
        orderId: created.id,
        status: "accepted"
    });

    return created;
}

function updateRequestStatus(requestId, status) {
    const allowed = [
        "pending",
        "accepted",
        "assigned",
        "en_route",
        "arrived",
        "picked_up",
        "completed",
        "cancelled"
    ];

    if (!allowed.includes(status)) {
        throw new Error(`Invalid request status: ${status}`);
    }

    const request = store.findById("requests", requestId);

    if (!request) {
        throw new Error("Request not found");
    }

    return store.update("requests", requestId, {
        status
    });
}

function updateOrderStatus(orderId, status) {
    const allowed = [
        "pending",
        "confirmed",
        "assigned",
        "en_route",
        "picked_up",
        "completed",
        "cancelled"
    ];

    if (!allowed.includes(status)) {
        throw new Error(`Invalid order status: ${status}`);
    }

    const order = store.findById("orders", orderId);

    if (!order) {
        throw new Error("Order not found");
    }

    return store.update("orders", orderId, {
        status
    });
}

function assignDriver(requestId, driverId) {
    const request = store.findById("requests", requestId);

    if (!request) {
        throw new Error("Request not found");
    }

    const driver = store.findById("drivers", driverId);

    if (!driver) {
        throw new Error("Driver not found");
    }

    const updated = store.update("requests", requestId, {
        assignedDriverId: driverId,
        status: "assigned"
    });

    if (request.orderId) {
        store.update("orders", request.orderId, {
            driverId,
            status: "assigned"
        });
    }

    return updated;
}

module.exports = {
    createCustomer,
    createRequest,
    createOrderFromRequest,
    updateRequestStatus,
    updateOrderStatus,
    assignDriver
};
JS

node --check api/domain-service.js
echo "✓ Real domain service installed"
echo

echo "[5] REAL SOCKET.IO® SERVER"
echo "--------------------------------------------------------------"

cat > realtime-server.js <<'JS'
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

io.on("connection", socket => {
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
JS

node --check realtime-server.js
echo "✓ Real Socket.IO® server installed"
echo

echo "[6] REAL PLATFORM API"
echo "--------------------------------------------------------------"

cat > api/platform-api.js <<'JS'
const express = require("express");

const store = require("./store");
const domain = require("./domain-service");

function createApi(eventBus, realtime) {
    const router = express.Router();

    function emit(event, payload) {
        if (eventBus) {
            eventBus.publish(event, payload);
        }

        if (realtime) {
            realtime.emit(event, payload);
        }
    }

    function asyncRoute(handler) {
        return async (req, res) => {
            try {
                await handler(req, res);
            } catch (error) {
                console.error(error);

                res.status(400).json({
                    error: error.message
                });
            }
        };
    }

    router.get("/health", (req, res) => {
        res.json({
            status: "healthy",
            service: "EB Platform® API",
            timestamp: new Date().toISOString()
        });
    });

    router.get("/customers", (req, res) => {
        res.json({
            data: store.all("customers")
        });
    });

    router.post(
        "/customers",
        asyncRoute(async (req, res) => {
            const customer = domain.createCustomer(req.body);

            emit("customer.created", customer);

            res.status(201).json({
                data: customer
            });
        })
    );

    router.get("/customers/:id", (req, res) => {
        const customer = store.findById(
            "customers",
            req.params.id
        );

        if (!customer) {
            return res.status(404).json({
                error: "Customer not found"
            });
        }

        res.json({
            data: customer
        });
    });

    router.get("/requests", (req, res) => {
        res.json({
            data: store.all("requests")
        });
    });

    router.post(
        "/requests",
        asyncRoute(async (req, res) => {
            const request = domain.createRequest(req.body);

            emit("request.created", request);

            res.status(201).json({
                data: request
            });
        })
    );

    router.get("/requests/:id", (req, res) => {
        const request = store.findById(
            "requests",
            req.params.id
        );

        if (!request) {
            return res.status(404).json({
                error: "Request not found"
            });
        }

        res.json({
            data: request
        });
    });

    router.post(
        "/requests/:id/accept",
        asyncRoute(async (req, res) => {
            const request = store.findById(
                "requests",
                req.params.id
            );

            if (!request) {
                return res.status(404).json({
                    error: "Request not found"
                });
            }

            const order = domain.createOrderFromRequest(request);

            const updated = store.findById(
                "requests",
                request.id
            );

            emit("request.accepted", updated);
            emit("order.created", order);

            res.status(201).json({
                request: updated,
                order
            });
        })
    );

    router.patch(
        "/requests/:id/status",
        asyncRoute(async (req, res) => {
            const request = domain.updateRequestStatus(
                req.params.id,
                req.body.status
            );

            emit("request.status.changed", request);

            res.json({
                data: request
            });
        })
    );

    router.post(
        "/requests/:id/assign",
        asyncRoute(async (req, res) => {
            const request = domain.assignDriver(
                req.params.id,
                req.body.driverId
            );

            emit("request.assigned", request);

            res.json({
                data: request
            });
        })
    );

    router.get("/orders", (req, res) => {
        res.json({
            data: store.all("orders")
        });
    });

    router.get("/orders/:id", (req, res) => {
        const order = store.findById(
            "orders",
            req.params.id
        );

        if (!order) {
            return res.status(404).json({
                error: "Order not found"
            });
        }

        res.json({
            data: order
        });
    });

    router.patch(
        "/orders/:id/status",
        asyncRoute(async (req, res) => {
            const order = domain.updateOrderStatus(
                req.params.id,
                req.body.status
            );

            emit("order.status.changed", order);

            res.json({
                data: order
            });
        })
    );

    router.get("/drivers", (req, res) => {
        res.json({
            data: store.all("drivers")
        });
    });

    router.post(
        "/drivers",
        asyncRoute(async (req, res) => {
            if (!req.body.name) {
                throw new Error("Driver name is required");
            }

            const driver = store.insert("drivers", {
                id: `drv_${Date.now()}`,
                name: String(req.body.name),
                phone: req.body.phone || null,
                status: "available",
                location: req.body.location || null,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            });

            emit("driver.created", driver);

            res.status(201).json({
                data: driver
            });
        })
    );

    router.get("/stats", (req, res) => {
        res.json({
            customers: store.count("customers"),
            requests: store.count("requests"),
            orders: store.count("orders"),
            drivers: store.count("drivers"),
            timestamp: new Date().toISOString()
        });
    });

    return router;
}

module.exports = createApi;
JS

node --check api/platform-api.js
echo "✓ Real API layer installed"
echo

echo "[7] INITIALIZE REAL DATABASE COLLECTIONS"
echo "--------------------------------------------------------------"

for collection in customers requests orders drivers locations payments notifications audit; do
    if [ ! -f "data/$collection.json" ]; then
        printf '[]\n' > "data/$collection.json"
    fi
done

echo "✓ Persistent collections initialized"
echo

echo "[8] PATCH NEXT SERVER WITH REAL API + REALTIME"
echo "--------------------------------------------------------------"

node <<'NODE'
const fs = require("fs");

const file = "server.js";
let src = fs.readFileSync(file, "utf8");

if (!src.includes("api/platform-api")) {
    src = src.replace(
        /const\s+.*?express.*?;\n/,
        match => match +
        'const EventBus = require("./framework/core/events/event-bus");\n' +
        'const createPlatformApi = require("./api/platform-api");\n' +
        'const { io: realtimeIO } = require("./realtime-server");\n'
    );

    const marker =
        "const app = express();";

    if (src.includes(marker)) {
        src = src.replace(
            marker,
            marker +
            "\n\nconst platformEventBus = new EventBus();\n" +
            "app.use(express.json());\n" +
            "app.use('/api', createPlatformApi(platformEventBus, realtimeIO));\n"
        );
    }
}

fs.writeFileSync(file, src);
NODE

node --check server.js || true

echo "✓ Server integration attempted"
echo

echo "[9] REPLACE PLATFORM START CONTROL"
echo "--------------------------------------------------------------"

cat > EB_PLATFORM.sh <<'BASH'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PID_DIR="$ROOT/.runtime"
NEXT_PID="$PID_DIR/next.pid"
REALTIME_PID="$PID_DIR/realtime.pid"

mkdir -p "$PID_DIR"

is_running() {
    local file="$1"

    [ -f "$file" ] || return 1

    local pid
    pid="$(cat "$file" 2>/dev/null || true)"

    [ -n "$pid" ] || return 1

    kill -0 "$pid" 2>/dev/null
}

get_lan_ip() {
    local ip=""

    if command -v ip >/dev/null 2>&1; then
        ip="$(
            ip -4 addr show 2>/dev/null |
            awk '/inet / && $2 !~ /^127\./ {
                split($2,a,"/");
                print a[1];
                exit
            }'
        )"
    fi

    printf '%s' "${ip:-127.0.0.1}"
}

wait_http() {
    local url="$1"

    for _ in $(seq 1 30); do
        if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
            return 0
        fi

        sleep 1
    done

    return 1
}

start_realtime() {
    if is_running "$REALTIME_PID"; then
        echo "✓ Realtime® already running"
        return
    fi

    echo "[1] Starting real Socket.IO® server..."

    nohup node "$ROOT/realtime-server.js" \
        > "$ROOT/.runtime/realtime.log" 2>&1 &

    echo $! > "$REALTIME_PID"

    sleep 1

    if is_running "$REALTIME_PID"; then
        echo "✓ Realtime® running — PID $(cat "$REALTIME_PID")"
    else
        echo "✗ Realtime® failed to start"
        tail -n 100 "$ROOT/.runtime/realtime.log" 2>/dev/null || true
        return 1
    fi
}

start_next() {
    if is_running "$NEXT_PID"; then
        echo "✓ Request Runner® already running"
        return
    fi

    echo "[2] Starting Request Runner®..."

    if [ "${NODE_ENV:-development}" = "production" ]; then
        nohup npm run start \
            > "$ROOT/.runtime/next.log" 2>&1 &
    else
        nohup npm run dev \
            > "$ROOT/.runtime/next.log" 2>&1 &
    fi

    echo $! > "$NEXT_PID"

    sleep 2

    if is_running "$NEXT_PID"; then
        echo "✓ Request Runner® running — PID $(cat "$NEXT_PID")"
    else
        echo "✗ Request Runner® failed to start"
        tail -n 100 "$ROOT/.runtime/next.log" 2>/dev/null || true
        return 1
    fi
}

stop() {
    echo "Stopping EB Platform®..."

    for file in "$NEXT_PID" "$REALTIME_PID"; do
        if [ -f "$file" ]; then
            pid="$(cat "$file" 2>/dev/null || true)"

            if [ -n "$pid" ]; then
                kill "$pid" 2>/dev/null || true
            fi

            rm -f "$file"
        fi
    done

    echo "✓ Platform stopped"
}

status() {
    local lan
    lan="$(get_lan_ip)"

    echo
    echo "=============================================================="
    echo " EB PLATFORM® — STATUS"
    echo "=============================================================="

    if curl -fsS --max-time 2 \
        http://127.0.0.1:3000/api/health \
        >/dev/null 2>&1; then
        echo "✓ API®            : HEALTHY"
    else
        echo "✗ API®            : DOWN"
    fi

    if curl -fsS --max-time 2 \
        http://127.0.0.1:3000/request \
        >/dev/null 2>&1; then
        echo "✓ Customer®       : HEALTHY"
    else
        echo "✗ Customer®       : DOWN"
    fi

    if curl -fsS --max-time 2 \
        http://127.0.0.1:3000/ops \
        >/dev/null 2>&1; then
        echo "✓ Operations®     : HEALTHY"
    else
        echo "✗ Operations®     : DOWN"
    fi

    if curl -fsS --max-time 2 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        >/dev/null 2>&1; then
        echo "✓ Realtime®       : HEALTHY"
    else
        echo "✗ Realtime®       : DOWN"
    fi

    echo
    echo "Customer:"
    echo "  http://127.0.0.1:3000/request"

    echo
    echo "Operations:"
    echo "  http://127.0.0.1:3000/ops"

    echo
    echo "API:"
    echo "  http://127.0.0.1:3000/api/health"

    echo
    echo "Realtime:"
    echo "  http://127.0.0.1:3001/health"

    echo
    echo "LAN:"
    echo "  http://${lan}:3000"

    echo
    echo "=============================================================="
}

case "${1:-status}" in
    start)
        start_realtime
        start_next
        ;;

    stop)
        stop
        ;;

    restart)
        stop
        sleep 1
        start_realtime
        start_next
        ;;

    status)
        status
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
BASH

chmod 700 EB_PLATFORM.sh

echo "✓ Platform controller upgraded"
echo

echo "[10] REAL FUNCTIONAL TEST"
echo "--------------------------------------------------------------"

cat > REAL_FUNCTIONAL_TEST.sh <<'BASH'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo
echo "=============================================================="
echo " EB PLATFORM® — REAL FUNCTIONAL TEST"
echo "=============================================================="
echo

echo "[1] START PLATFORM"
./EB_PLATFORM.sh start || true

sleep 2

echo
echo "[2] HEALTH"

if curl -fsS http://127.0.0.1:3000/api/health >/dev/null; then
    ok "API health"
else
    fail "API health"
fi

if curl -fsS http://127.0.0.1:3001/health >/dev/null; then
    ok "Realtime health"
else
    fail "Realtime health"
fi

echo
echo "[3] SOCKET.IO HANDSHAKE"

SOCKET="$(
    curl -fsS \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling"
)"

if printf '%s' "$SOCKET" | grep -q '"sid"'; then
    ok "Engine.IO handshake"
else
    fail "Engine.IO handshake"
fi

echo
echo "[4] REAL CUSTOMER CREATION"

CUSTOMER_RESPONSE="$(
    curl -fsS \
    -X POST \
    -H 'Content-Type: application/json' \
    -d '{"name":"Integration Customer","phone":"0000000000"}' \
    http://127.0.0.1:3000/api/customers
)"

CUSTOMER_ID="$(
    printf '%s' "$CUSTOMER_RESPONSE" |
    node -e '
        let s="";
        process.stdin.on("data",d=>s+=d);
        process.stdin.on("end",()=>{
            const x=JSON.parse(s);
            process.stdout.write(String(x.data.id));
        });
    '
)"

if [ -n "$CUSTOMER_ID" ]; then
    ok "Customer persisted: $CUSTOMER_ID"
else
    fail "Customer creation"
fi

echo
echo "[5] REAL REQUEST CREATION"

REQUEST_RESPONSE="$(
    curl -fsS \
    -X POST \
    -H 'Content-Type: application/json' \
    -d "{\"customerId\":\"$CUSTOMER_ID\",\"pickup\":\"Test Pickup\",\"destination\":\"Test Destination\"}" \
    http://127.0.0.1:3000/api/requests
)"

REQUEST_ID="$(
    printf '%s' "$REQUEST_RESPONSE" |
    node -e '
        let s="";
        process.stdin.on("data",d=>s+=d);
        process.stdin.on("end",()=>{
            const x=JSON.parse(s);
            process.stdout.write(String(x.data.id));
        });
    '
)"

if [ -n "$REQUEST_ID" ]; then
    ok "Request persisted: $REQUEST_ID"
else
    fail "Request creation"
fi

echo
echo "[6] REAL REQUEST ACCEPTANCE"

ORDER_RESPONSE="$(
    curl -fsS \
    -X POST \
    http://127.0.0.1:3000/api/requests/"$REQUEST_ID"/accept
)"

ORDER_ID="$(
    printf '%s' "$ORDER_RESPONSE" |
    node -e '
        let s="";
        process.stdin.on("data",d=>s+=d);
        process.stdin.on("end",()=>{
            const x=JSON.parse(s);
            process.stdout.write(String(x.order.id));
        });
    '
)"

if [ -n "$ORDER_ID" ]; then
    ok "Order created from request: $ORDER_ID"
else
    fail "Order creation"
fi

echo
echo "[7] REAL STATUS TRANSITION"

STATUS_RESPONSE="$(
    curl -fsS \
    -X PATCH \
    -H 'Content-Type: application/json' \
    -d '{"status":"completed"}' \
    http://127.0.0.1:3000/api/requests/"$REQUEST_ID"/status
)"

if printf '%s' "$STATUS_RESPONSE" | grep -q '"completed"'; then
    ok "Request status persisted"
else
    fail "Request status transition"
fi

echo
echo "[8] PERSISTENCE VERIFICATION"

if grep -q "$CUSTOMER_ID" data/customers.json; then
    ok "Customer exists on disk"
else
    fail "Customer persistence"
fi

if grep -q "$REQUEST_ID" data/requests.json; then
    ok "Request exists on disk"
else
    fail "Request persistence"
fi

if grep -q "$ORDER_ID" data/orders.json; then
    ok "Order exists on disk"
else
    fail "Order persistence"
fi

echo
echo "[9] FRAMEWORK TESTS"

if node tests/run.js >/dev/null; then
    ok "Framework test suite"
else
    fail "Framework test suite"
fi

echo
echo "[10] STATUS"

./EB_PLATFORM.sh status

echo
echo "=============================================================="
echo " REAL FUNCTIONAL RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "✓ EVERYTHING REAL — CORE FLOW VERIFIED"
    exit 0
fi

echo "✗ REAL FUNCTIONAL TEST FAILED"
exit 1
BASH

chmod 700 REAL_FUNCTIONAL_TEST.sh

echo "✓ Functional test installed"
echo

echo "[11] PACKAGE VERIFICATION"
echo "--------------------------------------------------------------"

node - <<'NODE'
const pkg = require("./package.json");

const required = [
    "socket.io",
    "socket.io-client",
    "express",
    "next"
];

for (const name of required) {
    try {
        require.resolve(name);
        console.log(`✓ ${name}`);
    } catch {
        console.error(`✗ ${name}`);
        process.exitCode = 1;
    }
}
NODE

echo
echo "[12] FINAL SYNTAX VERIFICATION"
echo "--------------------------------------------------------------"

find api framework realtime-server.js server.js -type f \
    \( -name '*.js' -o -name '*.mjs' \) \
    -print0 2>/dev/null |
while IFS= read -r -d '' file; do
    node --check "$file"
done

echo "✓ JavaScript syntax verified"

echo
echo "=============================================================="
echo " EB PLATFORM® — REAL UPGRADE INSTALLED"
echo "=============================================================="
echo
echo "Backup:"
echo "  $BACKUP"
echo
echo "Next command:"
echo "  ./REAL_FUNCTIONAL_TEST.sh"
echo
