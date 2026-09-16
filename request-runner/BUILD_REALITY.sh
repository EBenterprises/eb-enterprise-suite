#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.reality-backup-$STAMP"

echo "=============================================================="
echo " EB PLATFORM® — REALITY BUILD"
echo "=============================================================="
echo

mkdir -p "$BACKUP"
mkdir -p \
  data \
  framework/data \
  app/api/health \
  app/api/customers \
  app/api/requests \
  app/api/orders \
  app/api/drivers \
  app/api/locations \
  app/api/scheduling \
  app/api/payments \
  app/api/notifications \
  app/api/operations \
  app/api/administration

echo "[1] BACKUP CURRENT IMPLEMENTATION"
echo "--------------------------------------------------------------"

for f in \
  framework/data/repository.js \
  framework/data/adapters/json-repository.js \
  framework/core/events/event-bus.js \
  framework/index.js
do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP/$(basename "$f")"
  fi
done

echo "✓ Backup: $BACKUP"

echo
echo "[2] REAL PERSISTENCE ENGINE"
echo "--------------------------------------------------------------"

cat > framework/data/persistence.js <<'JS'
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT = path.resolve(__dirname, "../..");
const DATA_DIR = path.join(ROOT, "data");

fs.mkdirSync(DATA_DIR, { recursive: true });

function id(prefix = "id") {
    return `${prefix}_${Date.now()}_${crypto.randomBytes(6).toString("hex")}`;
}

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
            `Unable to read persistent collection "${collection}": ${error.message}`
        );
    }
}

function write(collection, records) {
    const file = fileFor(collection);
    const tmp = `${file}.tmp`;

    fs.writeFileSync(
        tmp,
        JSON.stringify(records, null, 2),
        "utf8"
    );

    fs.renameSync(tmp, file);

    return records;
}

function now() {
    return new Date().toISOString();
}

class PersistentRepository {
    constructor(collection) {
        if (!collection) {
            throw new TypeError("PersistentRepository requires a collection");
        }

        this.collection = collection;
    }

    all() {
        return read(this.collection);
    }

    findById(recordId) {
        return this.all().find(item => item.id === recordId) || null;
    }

    findBy(field, value) {
        return this.all().filter(item => item[field] === value);
    }

    create(input = {}) {
        const timestamp = now();

        const record = {
            id: input.id || id(this.collection),
            ...input,
            createdAt: input.createdAt || timestamp,
            updatedAt: timestamp
        };

        const records = this.all();
        records.push(record);
        write(this.collection, records);

        return record;
    }

    update(recordId, patch = {}) {
        const records = this.all();
        const index = records.findIndex(item => item.id === recordId);

        if (index === -1) {
            return null;
        }

        records[index] = {
            ...records[index],
            ...patch,
            id: records[index].id,
            updatedAt: now()
        };

        write(this.collection, records);

        return records[index];
    }

    delete(recordId) {
        const records = this.all();
        const index = records.findIndex(item => item.id === recordId);

        if (index === -1) {
            return null;
        }

        const removed = records.splice(index, 1)[0];

        write(this.collection, records);

        return removed;
    }

    count() {
        return this.all().length;
    }

    clear() {
        write(this.collection, []);
    }
}

module.exports = {
    PersistentRepository,
    DATA_DIR,
    id,
    now
};
JS

echo "✓ PersistentRepository created"

echo
echo "[3] REAL EVENTBUS"
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

        return () => this.emitter.off(event, handler);
    }

    subscribe(event, handler) {
        return this.on(event, handler);
    }

    once(event, handler) {
        return this.emitter.once(event, handler);
    }

    emit(event, payload) {
        return this.emitter.emit(event, payload);
    }

    publish(event, payload) {
        return this.emit(event, payload);
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

echo "✓ EventBus now exposes both native and platform APIs"

echo
echo "[4] REAL APPLICATION SERVICE"
echo "--------------------------------------------------------------"

cat > framework/application-service.js <<'JS'
const EventBus = require("./core/events/event-bus");
const {
    PersistentRepository
} = require("./data/persistence");

const eventBus = new EventBus();

const repositories = new Map();

function repository(collection) {
    if (!repositories.has(collection)) {
        repositories.set(
            collection,
            new PersistentRepository(collection)
        );
    }

    return repositories.get(collection);
}

function validateEntity(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw new TypeError("Request body must be a JSON object");
    }

    return input;
}

function list(collection, filters = {}) {
    let records = repository(collection).all();

    for (const [key, value] of Object.entries(filters)) {
        if (
            value !== undefined &&
            value !== null &&
            value !== ""
        ) {
            records = records.filter(
                record => String(record[key]) === String(value)
            );
        }
    }

    return records;
}

function get(collection, id) {
    return repository(collection).findById(id);
}

function create(collection, input) {
    const data = validateEntity(input);

    const record = repository(collection).create(data);

    eventBus.publish(`${collection}.created`, record);
    eventBus.publish("entity.created", {
        collection,
        record
    });

    return record;
}

function update(collection, id, input) {
    const data = validateEntity(input);

    const record = repository(collection).update(id, data);

    if (!record) {
        return null;
    }

    eventBus.publish(`${collection}.updated`, record);
    eventBus.publish("entity.updated", {
        collection,
        record
    });

    return record;
}

function remove(collection, id) {
    const record = repository(collection).delete(id);

    if (!record) {
        return null;
    }

    eventBus.publish(`${collection}.deleted`, record);
    eventBus.publish("entity.deleted", {
        collection,
        record
    });

    return record;
}

function summary() {
    const collections = [
        "customers",
        "requests",
        "orders",
        "drivers",
        "locations",
        "scheduling",
        "payments",
        "notifications",
        "operations",
        "administration"
    ];

    const counts = {};

    for (const collection of collections) {
        counts[collection] = repository(collection).count();
    }

    return {
        timestamp: new Date().toISOString(),
        collections: counts
    };
}

module.exports = {
    eventBus,
    repository,
    list,
    get,
    create,
    update,
    remove,
    summary
};
JS

echo "✓ Application service created"

echo
echo "[5] REAL API ROUTE FACTORY"
echo "--------------------------------------------------------------"

cat > framework/api/crud-route.js <<'JS'
const service = require("../application-service");

function json(data, status = 200) {
    return Response.json(data, {
        status,
        headers: {
            "Cache-Control": "no-store"
        }
    });
}

async function body(request) {
    try {
        return await request.json();
    } catch {
        return {};
    }
}

function createCrudHandlers(collection) {
    return {
        async GET(request) {
            const { searchParams } = new URL(request.url);

            const filters = Object.fromEntries(
                searchParams.entries()
            );

            return json({
                ok: true,
                collection,
                data: service.list(collection, filters)
            });
        },

        async POST(request) {
            try {
                const input = await body(request);
                const record = service.create(collection, input);

                return json(
                    {
                        ok: true,
                        collection,
                        data: record
                    },
                    201
                );
            } catch (error) {
                return json(
                    {
                        ok: false,
                        error: error.message
                    },
                    400
                );
            }
        }
    };
}

function createIdHandlers(collection) {
    return {
        async GET(_request, context) {
            const { id } = await context.params;
            const record = service.get(collection, id);

            if (!record) {
                return json(
                    {
                        ok: false,
                        error: "Not found"
                    },
                    404
                );
            }

            return json({
                ok: true,
                collection,
                data: record
            });
        },

        async PATCH(request, context) {
            try {
                const { id } = await context.params;
                const input = await body(request);

                const record = service.update(
                    collection,
                    id,
                    input
                );

                if (!record) {
                    return json(
                        {
                            ok: false,
                            error: "Not found"
                        },
                        404
                    );
                }

                return json({
                    ok: true,
                    collection,
                    data: record
                });
            } catch (error) {
                return json(
                    {
                        ok: false,
                        error: error.message
                    },
                    400
                );
            }
        },

        async DELETE(_request, context) {
            const { id } = await context.params;

            const record = service.remove(collection, id);

            if (!record) {
                return json(
                    {
                        ok: false,
                        error: "Not found"
                    },
                    404
                );
            }

            return json({
                ok: true,
                collection,
                data: record
            });
        }
    };
}

module.exports = {
    createCrudHandlers,
    createIdHandlers
};
JS

echo "✓ CRUD route engine created"

echo
echo "[6] REAL API ROUTES"
echo "--------------------------------------------------------------"

make_collection_route() {
    local collection="$1"
    local dir="app/api/$collection"

    mkdir -p "$dir"

    cat > "$dir/route.js" <<JS
const {
    createCrudHandlers
} = require("../../../../framework/api/crud-route");

const handlers = createCrudHandlers("$collection");

export const GET = handlers.GET;
export const POST = handlers.POST;
JS

    mkdir -p "$dir/[id]"

    cat > "$dir/[id]/route.js" <<JS
const {
    createIdHandlers
} = require("../../../../../framework/api/crud-route");

const handlers = createIdHandlers("$collection");

export const GET = handlers.GET;
export const PATCH = handlers.PATCH;
export const DELETE = handlers.DELETE;
JS
}

for collection in \
    customers \
    requests \
    orders \
    drivers \
    locations \
    scheduling \
    payments \
    notifications \
    operations \
    administration
do
    make_collection_route "$collection"
done

echo "✓ CRUD APIs generated"

echo
echo "[7] REAL HEALTH API"
echo "--------------------------------------------------------------"

cat > app/api/health/route.js <<'JS'
const service = require("../../../framework/application-service");

export const dynamic = "force-dynamic";

export async function GET() {
    const summary = service.summary();

    return Response.json({
        ok: true,
        platform: "EB Platform®",
        status: "healthy",
        timestamp: new Date().toISOString(),
        persistence: "json",
        data: summary.collections
    });
}
JS

echo "✓ /api/health"

echo
echo "[8] REALTIME → APPLICATION EVENTS"
echo "--------------------------------------------------------------"

cat > realtime-server.js <<'JS'
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
JS

echo "✓ Realtime now bridges persistent application events"

echo
echo "[9] REAL DATA FILES"
echo "--------------------------------------------------------------"

for collection in \
    customers \
    requests \
    orders \
    drivers \
    locations \
    scheduling \
    payments \
    notifications \
    operations \
    administration
do
    file="data/$collection.json"

    if [ ! -f "$file" ]; then
        printf '[]\n' > "$file"
    fi
done

echo "✓ Persistent collections initialized"

echo
echo "[10] DATA INTEGRITY TEST"
echo "--------------------------------------------------------------"

node <<'NODE'
const service = require("./framework/application-service");

const testCollection = "__reality_test";

service.repository(testCollection).clear();

const created = service.create(testCollection, {
    type: "integration",
    value: "real"
});

if (!created.id) {
    throw new Error("Create failed");
}

const loaded = service.get(testCollection, created.id);

if (!loaded) {
    throw new Error("Persistence read failed");
}

const updated = service.update(
    testCollection,
    created.id,
    {
        value: "updated"
    }
);

if (!updated || updated.value !== "updated") {
    throw new Error("Persistence update failed");
}

const removed = service.remove(
    testCollection,
    created.id
);

if (!removed) {
    throw new Error("Persistence delete failed");
}

if (service.get(testCollection, created.id)) {
    throw new Error("Delete verification failed");
}

service.repository(testCollection).clear();

console.log("✓ CREATE");
console.log("✓ READ");
console.log("✓ UPDATE");
console.log("✓ DELETE");
console.log("✓ Durable persistence round-trip");
NODE

rm -f data/__reality_test.json

echo
echo "[11] JAVASCRIPT SYNTAX"
echo "--------------------------------------------------------------"

while IFS= read -r file; do
    case "$file" in
        ./node_modules/*|./.next/*)
            continue
            ;;
    esac

    node --check "$file" >/dev/null
done < <(
    find app apps framework -type f -name '*.js' | sort
)

echo "✓ JavaScript syntax clean"

echo
echo "[12] BUILD"
echo "--------------------------------------------------------------"

npm run build

echo
echo "=============================================================="
echo " EB PLATFORM® — REALITY BUILD COMPLETE"
echo "=============================================================="
echo
echo "REAL PERSISTENCE:"
echo "  ./data/*.json"
echo
echo "REAL APIs:"
echo "  GET/POST    /api/customers"
echo "  GET/PATCH/DELETE /api/customers/:id"
echo "  GET/POST    /api/requests"
echo "  GET/PATCH/DELETE /api/requests/:id"
echo "  GET/POST    /api/orders"
echo "  GET/PATCH/DELETE /api/orders/:id"
echo "  GET/POST    /api/drivers"
echo "  GET/PATCH/DELETE /api/drivers/:id"
echo "  GET/POST    /api/locations"
echo "  GET/PATCH/DELETE /api/locations/:id"
echo "  GET/POST    /api/scheduling"
echo "  GET/PATCH/DELETE /api/scheduling/:id"
echo "  GET/POST    /api/payments"
echo "  GET/PATCH/DELETE /api/payments/:id"
echo "  GET/POST    /api/notifications"
echo "  GET/PATCH/DELETE /api/notifications/:id"
echo "  GET/POST    /api/operations"
echo "  GET/PATCH/DELETE /api/operations/:id"
echo "  GET/POST    /api/administration"
echo "  GET/PATCH/DELETE /api/administration/:id"
echo
echo "HEALTH:"
echo "  /api/health"
echo
echo "REALTIME:"
echo "  Socket.IO® :3001"
echo
echo "=============================================================="
