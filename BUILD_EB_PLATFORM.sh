#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="$HOME/request-runner"
FRAMEWORK="$APP/framework"
APPS="$APP/apps"
INFRA="$APP/infrastructure"
BIN="$APP/bin"
CONFIG="$APP/config"
DATA="$APP/data"
TESTS="$APP/tests"
DOCS="$APP/docs"

echo "=============================================================="
echo " EB PLATFORM® — FOUNDATIONAL BUILD"
echo " Request Runner® Application Platform"
echo "=============================================================="

if [ ! -d "$APP" ]; then
    echo "ERROR: $APP does not exist."
    echo "Install the Request Runner® application first."
    exit 1
fi

cd "$APP"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$APP/.platform-backup-$STAMP"

echo
echo "[1/14] Creating immutable safety backup..."
mkdir -p "$BACKUP"

cp -a package.json "$BACKUP/" 2>/dev/null || true
cp -a server.js "$BACKUP/" 2>/dev/null || true
cp -a next.config.js "$BACKUP/" 2>/dev/null || true
cp -a app "$BACKUP/" 2>/dev/null || true
cp -a data "$BACKUP/" 2>/dev/null || true

echo "Backup: $BACKUP"

echo
echo "[2/14] Creating platform topology..."

mkdir -p \
    "$FRAMEWORK/runtime" \
    "$FRAMEWORK/core" \
    "$FRAMEWORK/core/container" \
    "$FRAMEWORK/core/modules" \
    "$FRAMEWORK/core/commands" \
    "$FRAMEWORK/core/queries" \
    "$FRAMEWORK/core/events" \
    "$FRAMEWORK/core/middleware" \
    "$FRAMEWORK/core/errors" \
    "$FRAMEWORK/domain" \
    "$FRAMEWORK/data" \
    "$FRAMEWORK/data/adapters" \
    "$FRAMEWORK/api" \
    "$FRAMEWORK/realtime" \
    "$FRAMEWORK/security" \
    "$FRAMEWORK/observability" \
    "$FRAMEWORK/extensions" \
    "$APPS/request-runner" \
    "$APPS/request-runner/customer" \
    "$APPS/request-runner/operations" \
    "$APPS/request-runner/dispatch" \
    "$APPS/request-runner/administration" \
    "$INFRA/android" \
    "$INFRA/local" \
    "$INFRA/linux" \
    "$INFRA/cloud" \
    "$BIN" \
    "$CONFIG" \
    "$TESTS/unit" \
    "$TESTS/integration" \
    "$TESTS/e2e" \
    "$DOCS"

echo "✓ Platform directories created"

echo
echo "[3/14] Building EB Runtime®..."

cat > "$FRAMEWORK/runtime/environment.js" <<'JS'
const os = require("os");

function detectEnvironment() {
    const platform = process.platform;
    const architecture = process.arch;

    return {
        platform,
        architecture,
        android: platform === "android",
        linux: platform === "linux",
        darwin: platform === "darwin",
        windows: platform === "win32",
        arm64: architecture === "arm64",
        node: process.version,
        hostname: os.hostname(),
        cpuCount: os.cpus().length
    };
}

module.exports = {
    detectEnvironment
};
JS

cat > "$FRAMEWORK/runtime/config.js" <<'JS'
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "../..");

function loadConfig() {
    const file = path.join(root, "config", "platform.json");

    if (!fs.existsSync(file)) {
        return {};
    }

    return JSON.parse(fs.readFileSync(file, "utf8"));
}

module.exports = {
    loadConfig
};
JS

cat > "$FRAMEWORK/runtime/logger.js" <<'JS'
function timestamp() {
    return new Date().toISOString();
}

function write(level, message, metadata = {}) {
    const record = {
        timestamp: timestamp(),
        level,
        message,
        ...metadata
    };

    console.log(JSON.stringify(record));
}

module.exports = {
    info: (message, metadata) => write("info", message, metadata),
    warn: (message, metadata) => write("warn", message, metadata),
    error: (message, metadata) => write("error", message, metadata),
    debug: (message, metadata) => write("debug", message, metadata)
};
JS

echo
echo "[4/14] Building EB Core®..."

cat > "$FRAMEWORK/core/container/index.js" <<'JS'
class Container {
    constructor() {
        this.services = new Map();
        this.factories = new Map();
        this.singletons = new Map();
    }

    register(name, value) {
        this.services.set(name, value);
        return this;
    }

    factory(name, factory) {
        this.factories.set(name, factory);
        return this;
    }

    singleton(name, factory) {
        this.factories.set(name, factory);
        this.singletons.set(name, undefined);
        return this;
    }

    resolve(name) {
        if (this.services.has(name)) {
            return this.services.get(name);
        }

        if (!this.factories.has(name)) {
            throw new Error(`Service not registered: ${name}`);
        }

        if (this.singletons.has(name)) {
            let instance = this.singletons.get(name);

            if (instance === undefined) {
                instance = this.factories.get(name)(this);
                this.singletons.set(name, instance);
            }

            return instance;
        }

        return this.factories.get(name)(this);
    }

    has(name) {
        return (
            this.services.has(name) ||
            this.factories.has(name)
        );
    }
}

module.exports = Container;
JS

cat > "$FRAMEWORK/core/events/event-bus.js" <<'JS'
const { EventEmitter } = require("events");

class EventBus {
    constructor() {
        this.emitter = new EventEmitter();
        this.emitter.setMaxListeners(1000);
    }

    on(event, handler) {
        this.emitter.on(event, handler);
        return () => this.emitter.off(event, handler);
    }

    once(event, handler) {
        this.emitter.once(event, handler);
    }

    emit(event, payload) {
        return this.emitter.emit(event, payload);
    }

    removeAll(event) {
        this.emitter.removeAllListeners(event);
    }
}

module.exports = EventBus;
JS

cat > "$FRAMEWORK/core/commands/command-bus.js" <<'JS'
class CommandBus {
    constructor() {
        this.handlers = new Map();
    }

    register(command, handler) {
        if (this.handlers.has(command)) {
            throw new Error(`Command already registered: ${command}`);
        }

        this.handlers.set(command, handler);
    }

    async execute(command, payload) {
        const handler = this.handlers.get(command);

        if (!handler) {
            throw new Error(`Command handler not found: ${command}`);
        }

        return handler(payload);
    }
}

module.exports = CommandBus;
JS

cat > "$FRAMEWORK/core/queries/query-bus.js" <<'JS'
class QueryBus {
    constructor() {
        this.handlers = new Map();
    }

    register(query, handler) {
        if (this.handlers.has(query)) {
            throw new Error(`Query already registered: ${query}`);
        }

        this.handlers.set(query, handler);
    }

    async execute(query, payload) {
        const handler = this.handlers.get(query);

        if (!handler) {
            throw new Error(`Query handler not found: ${query}`);
        }

        return handler(payload);
    }
}

module.exports = QueryBus;
JS

cat > "$FRAMEWORK/core/modules/module-registry.js" <<'JS'
class ModuleRegistry {
    constructor() {
        this.modules = new Map();
    }

    register(module) {
        if (!module || !module.name) {
            throw new Error("Invalid module");
        }

        if (this.modules.has(module.name)) {
            throw new Error(`Module already registered: ${module.name}`);
        }

        this.modules.set(module.name, module);
        return module;
    }

    get(name) {
        return this.modules.get(name);
    }

    list() {
        return [...this.modules.values()];
    }

    async initialize(context) {
        for (const module of this.modules.values()) {
            if (typeof module.initialize === "function") {
                await module.initialize(context);
            }
        }
    }

    async shutdown(context) {
        const modules = [...this.modules.values()].reverse();

        for (const module of modules) {
            if (typeof module.shutdown === "function") {
                await module.shutdown(context);
            }
        }
    }
}

module.exports = ModuleRegistry;
JS

cat > "$FRAMEWORK/core/middleware/pipeline.js" <<'JS'
class Pipeline {
    constructor() {
        this.middleware = [];
    }

    use(handler) {
        this.middleware.push(handler);
        return this;
    }

    async execute(context, terminal = async () => context) {
        let index = -1;

        const dispatch = async (position, current) => {
            if (position <= index) {
                throw new Error("Middleware called next() multiple times");
            }

            index = position;

            const handler = this.middleware[position];

            if (!handler) {
                return terminal(current);
            }

            return handler(
                current,
                nextContext => dispatch(position + 1, nextContext)
            );
        };

        return dispatch(0, context);
    }
}

module.exports = Pipeline;
JS

cat > "$FRAMEWORK/core/errors/platform-error.js" <<'JS'
class PlatformError extends Error {
    constructor(message, options = {}) {
        super(message);

        this.name = options.name || "PlatformError";
        this.code = options.code || "PLATFORM_ERROR";
        this.status = options.status || 500;
        this.details = options.details || {};
    }
}

module.exports = PlatformError;
JS

echo
echo "[5/14] Building EB Data® abstraction..."

cat > "$FRAMEWORK/data/repository.js" <<'JS'
class Repository {
    async findById() {
        throw new Error("findById() not implemented");
    }

    async findAll() {
        throw new Error("findAll() not implemented");
    }

    async create() {
        throw new Error("create() not implemented");
    }

    async update() {
        throw new Error("update() not implemented");
    }

    async delete() {
        throw new Error("delete() not implemented");
    }
}

module.exports = Repository;
JS

cat > "$FRAMEWORK/data/adapters/json-repository.js" <<'JS'
const fs = require("fs");
const path = require("path");
const Repository = require("../repository");

class JsonRepository extends Repository {
    constructor(file) {
        super();
        this.file = path.resolve(file);
        this.ensure();
    }

    ensure() {
        fs.mkdirSync(path.dirname(this.file), { recursive: true });

        if (!fs.existsSync(this.file)) {
            fs.writeFileSync(this.file, "[]\n");
        }
    }

    read() {
        this.ensure();
        return JSON.parse(fs.readFileSync(this.file, "utf8"));
    }

    write(records) {
        const temp = `${this.file}.tmp`;

        fs.writeFileSync(
            temp,
            JSON.stringify(records, null, 2) + "\n"
        );

        fs.renameSync(temp, this.file);
    }

    async findAll() {
        return this.read();
    }

    async findById(id) {
        return this.read().find(item => item.id === id) || null;
    }

    async create(record) {
        const records = this.read();
        records.push(record);
        this.write(records);
        return record;
    }

    async update(id, changes) {
        const records = this.read();
        const index = records.findIndex(item => item.id === id);

        if (index === -1) {
            return null;
        }

        records[index] = {
            ...records[index],
            ...changes
        };

        this.write(records);

        return records[index];
    }

    async delete(id) {
        const records = this.read();
        const filtered = records.filter(item => item.id !== id);

        this.write(filtered);

        return filtered.length !== records.length;
    }
}

module.exports = JsonRepository;
JS

echo
echo "[6/14] Building EB Domain®..."

cat > "$FRAMEWORK/domain/entity.js" <<'JS'
class Entity {
    constructor(data = {}) {
        Object.assign(this, data);

        if (!this.id) {
            this.id = Entity.id();
        }

        if (!this.createdAt) {
            this.createdAt = new Date().toISOString();
        }

        this.updatedAt = new Date().toISOString();
    }

    touch() {
        this.updatedAt = new Date().toISOString();
        return this;
    }

    static id() {
        return (
            Date.now().toString(36) +
            "-" +
            Math.random().toString(36).slice(2, 10)
        );
    }
}

module.exports = Entity;
JS

cat > "$FRAMEWORK/domain/request.js" <<'JS'
const Entity = require("./entity");

class Request extends Entity {
    constructor(data = {}) {
        super(data);

        this.type = data.type || "general";
        this.status = data.status || "pending";
        this.customerId = data.customerId || null;
        this.location = data.location || null;
        this.notes = data.notes || "";
    }

    transition(status) {
        this.status = status;
        return this.touch();
    }
}

module.exports = Request;
JS

cat > "$FRAMEWORK/domain/order.js" <<'JS'
const Entity = require("./entity");

class Order extends Entity {
    constructor(data = {}) {
        super(data);

        this.requestId = data.requestId || null;
        this.customerId = data.customerId || null;
        this.status = data.status || "created";
        this.total = Number(data.total || 0);
        this.currency = data.currency || "CAD";
    }

    transition(status) {
        this.status = status;
        return this.touch();
    }
}

module.exports = Order;
JS

echo
echo "[7/14] Building EB API® and EB Realtime®..."

cat > "$FRAMEWORK/api/router.js" <<'JS'
class Router {
    constructor() {
        this.routes = [];
    }

    register(method, path, handler) {
        this.routes.push({
            method: method.toUpperCase(),
            path,
            handler
        });

        return this;
    }

    match(method, path) {
        return this.routes.find(
            route =>
                route.method === method.toUpperCase() &&
                route.path === path
        );
    }

    list() {
        return [...this.routes];
    }
}

module.exports = Router;
JS

cat > "$FRAMEWORK/realtime/realtime-bus.js" <<'JS'
class RealtimeBus {
    constructor(io = null) {
        this.io = io;
    }

    attach(io) {
        this.io = io;
        return this;
    }

    publish(event, payload, room = null) {
        if (!this.io) {
            return false;
        }

        if (room) {
            this.io.to(room).emit(event, payload);
        } else {
            this.io.emit(event, payload);
        }

        return true;
    }
}

module.exports = RealtimeBus;
JS

echo
echo "[8/14] Building EB Security®..."

cat > "$FRAMEWORK/security/authorization.js" <<'JS'
class Authorization {
    constructor() {
        this.permissions = new Map();
    }

    grant(role, permission) {
        if (!this.permissions.has(role)) {
            this.permissions.set(role, new Set());
        }

        this.permissions.get(role).add(permission);
    }

    revoke(role, permission) {
        this.permissions.get(role)?.delete(permission);
    }

    allows(role, permission) {
        return Boolean(
            this.permissions.get(role)?.has(permission)
        );
    }
}

module.exports = Authorization;
JS

cat > "$FRAMEWORK/security/audit.js" <<'JS'
class Audit {
    constructor(repository = null) {
        this.repository = repository;
    }

    async record(event) {
        const record = {
            id: Date.now().toString(36),
            timestamp: new Date().toISOString(),
            ...event
        };

        if (this.repository) {
            await this.repository.create(record);
        }

        return record;
    }
}

module.exports = Audit;
JS

echo
echo "[9/14] Building EB Observability®..."

cat > "$FRAMEWORK/observability/health.js" <<'JS'
class Health {
    constructor() {
        this.checks = new Map();
    }

    register(name, check) {
        this.checks.set(name, check);
    }

    async check() {
        const results = {};

        for (const [name, check] of this.checks) {
            try {
                const result = await check();

                results[name] = {
                    status: "ok",
                    ...(result || {})
                };
            } catch (error) {
                results[name] = {
                    status: "error",
                    error: error.message
                };
            }
        }

        const failed = Object.values(results)
            .some(result => result.status !== "ok");

        return {
            status: failed ? "degraded" : "ok",
            timestamp: new Date().toISOString(),
            checks: results
        };
    }
}

module.exports = Health;
JS

echo
echo "[10/14] Building EB Application Kernel®..."

cat > "$FRAMEWORK/core/application.js" <<'JS'
const Container = require("./container");
const EventBus = require("./events/event-bus");
const CommandBus = require("./commands/command-bus");
const QueryBus = require("./queries/query-bus");
const ModuleRegistry = require("./modules/module-registry");
const Pipeline = require("./middleware/pipeline");
const Health = require("../observability/health");

class Application {
    constructor() {
        this.container = new Container();
        this.events = new EventBus();
        this.commands = new CommandBus();
        this.queries = new QueryBus();
        this.modules = new ModuleRegistry();
        this.middleware = new Pipeline();
        this.health = new Health();
        this.started = false;
    }

    register(name, value) {
        this.container.register(name, value);
        return this;
    }

    module(module) {
        this.modules.register(module);
        return this;
    }

    async start() {
        if (this.started) {
            return this;
        }

        await this.modules.initialize(this);

        this.started = true;

        this.events.emit("platform.started", {
            timestamp: new Date().toISOString()
        });

        return this;
    }

    async stop() {
        if (!this.started) {
            return;
        }

        await this.modules.shutdown(this);

        this.started = false;

        this.events.emit("platform.stopped", {
            timestamp: new Date().toISOString()
        });
    }

    async status() {
        return {
            running: this.started,
            modules: this.modules.list().map(module => module.name),
            health: await this.health.check()
        };
    }
}

module.exports = Application;
JS

cat > "$FRAMEWORK/index.js" <<'JS'
module.exports = {
    Application: require("./core/application"),
    Container: require("./core/container"),
    EventBus: require("./core/events/event-bus"),
    CommandBus: require("./core/commands/command-bus"),
    QueryBus: require("./core/queries/query-bus"),
    ModuleRegistry: require("./core/modules/module-registry"),
    Pipeline: require("./core/middleware/pipeline"),
    Repository: require("./data/repository"),
    JsonRepository: require("./data/adapters/json-repository"),
    Entity: require("./domain/entity"),
    Request: require("./domain/request"),
    Order: require("./domain/order"),
    Router: require("./api/router"),
    RealtimeBus: require("./realtime/realtime-bus"),
    Authorization: require("./security/authorization"),
    Audit: require("./security/audit"),
    Health: require("./observability/health"),
    environment: require("./runtime/environment"),
    config: require("./runtime/config"),
    logger: require("./runtime/logger")
};
JS

echo
echo "[11/14] Building Request Runner® application modules..."

for MODULE in customers requests orders dispatch drivers locations scheduling payments notifications operations administration; do

cat > "$APPS/request-runner/$MODULE.js" <<JS
module.exports = {
    name: "$MODULE",

    async initialize(app) {
        app.health.register("$MODULE", async () => ({
            module: "$MODULE"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
JS

done

cat > "$APPS/request-runner/index.js" <<'JS'
const modules = [
    require("./customers"),
    require("./requests"),
    require("./orders"),
    require("./dispatch"),
    require("./drivers"),
    require("./locations"),
    require("./scheduling"),
    require("./payments"),
    require("./notifications"),
    require("./operations"),
    require("./administration")
];

module.exports = modules;
JS

echo
echo "[12/14] Creating platform configuration..."

cat > "$CONFIG/platform.json" <<'JSON'
{
  "platform": {
    "name": "EB Platform®",
    "version": "1.0.0",
    "application": "Request Runner®"
  },

  "runtime": {
    "environment": "development",
    "host": "0.0.0.0",
    "webPort": 3000,
    "realtimePort": 3001
  },

  "architecture": {
    "kernel": "EB Core®",
    "data": "EB Data®",
    "api": "EB API®",
    "realtime": "EB Realtime®",
    "security": "EB Security®",
    "observability": "EB Observability®"
  },

  "deployment": {
    "targetIndependent": true,
    "androidTermux": true,
    "cloudReady": true,
    "distributedReady": true
  }
}
JSON

cat > "$CONFIG/modules.json" <<'JSON'
{
  "enabled": [
    "customers",
    "requests",
    "orders",
    "dispatch",
    "drivers",
    "locations",
    "scheduling",
    "payments",
    "notifications",
    "operations",
    "administration"
  ]
}
JSON

echo
echo "[13/14] Creating authoritative EB CLI®..."

cat > "$BIN/eb" <<'CLI'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="$HOME/request-runner"
cd "$APP"

COMMAND="${1:-help}"

case "$COMMAND" in

start)
    exec "$APP/bin/start"
    ;;

stop)
    "$APP/bin/stop"
    ;;

status)
    node "$APP/bin/status.js"
    ;;

doctor)
    node "$APP/bin/doctor.js"
    ;;

test)
    node "$APP/tests/run.js"
    ;;

backup)
    "$APP/bin/backup"
    ;;

help|*)
    cat <<'HELP'

EB Platform® CLI

Usage:

  eb start       Start Request Runner®
  eb stop        Stop Request Runner®
  eb status      Platform status
  eb doctor      Platform diagnostics
  eb test        Run platform tests
  eb backup      Create application backup

HELP
    ;;

esac
CLI

chmod +x "$BIN/eb"

cat > "$BIN/status.js" <<'JS'
const {
    Application,
    environment
} = require("../framework");

const app = new Application();

(async () => {
    const modules = require("../apps/request-runner");

    for (const module of modules) {
        app.module(module);
    }

    await app.start();

    const status = await app.status();

    console.log(JSON.stringify({
        platform: "EB Platform®",
        application: "Request Runner®",
        environment: environment.detectEnvironment(),
        ...status
    }, null, 2));

    await app.stop();
})().catch(error => {
    console.error(error);
    process.exit(1);
});
JS

cat > "$BIN/doctor.js" <<'JS'
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");

const checks = [];

function check(name, test) {
    try {
        test();
        checks.push({ name, status: "ok" });
    } catch (error) {
        checks.push({
            name,
            status: "error",
            error: error.message
        });
    }
}

check("package.json", () =>
    fs.accessSync(path.join(root, "package.json"))
);

check("framework", () =>
    fs.accessSync(path.join(root, "framework", "index.js"))
);

check("kernel", () =>
    fs.accessSync(path.join(root, "framework", "core", "application.js"))
);

check("data layer", () =>
    fs.accessSync(path.join(root, "framework", "data", "repository.js"))
);

check("realtime layer", () =>
    fs.accessSync(path.join(root, "framework", "realtime", "realtime-bus.js"))
);

check("security layer", () =>
    fs.accessSync(path.join(root, "framework", "security", "audit.js"))
);

check("configuration", () =>
    fs.accessSync(path.join(root, "config", "platform.json"))
);

check("Request Runner modules", () =>
    fs.accessSync(path.join(root, "apps", "request-runner", "index.js"))
);

const failed = checks.some(item => item.status !== "ok");

console.log(JSON.stringify({
    platform: "EB Platform®",
    status: failed ? "failed" : "healthy",
    checks
}, null, 2));

process.exit(failed ? 1 : 0);
JS

cat > "$BIN/start" <<'START'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="$HOME/request-runner"
cd "$APP"

echo "================================================"
echo " EB Platform®"
echo " Request Runner®"
echo "================================================"
echo

if [ ! -f "$APP/run-request-runner.sh" ]; then
    echo "ERROR: Existing Request Runner launcher is missing."
    exit 1
fi

exec "$APP/run-request-runner.sh"
START

chmod +x "$BIN/start"

cat > "$BIN/stop" <<'STOP'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="$HOME/request-runner"

pkill -f "$APP/realtime-server.js" 2>/dev/null || true
pkill -f "next dev --webpack" 2>/dev/null || true

echo "Request Runner® stopped."
STOP

chmod +x "$BIN/stop"

cat > "$BIN/backup" <<'BACKUP'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

APP="$HOME/request-runner"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$HOME/request-runner-backups/$STAMP"

mkdir -p "$DEST"

cp -a "$APP" "$DEST/request-runner"

rm -rf "$DEST/request-runner/.next"
rm -rf "$DEST/request-runner/node_modules"
rm -rf "$DEST/request-runner/.repair-backup-"*
rm -rf "$DEST/request-runner/.platform-backup-"*

echo "Backup created:"
echo "$DEST"
BACKUP

chmod +x "$BIN/backup"

cat > "$TESTS/run.js" <<'JS'
const assert = require("assert");

const {
    Application,
    Container,
    EventBus,
    CommandBus,
    QueryBus,
    JsonRepository,
    Entity,
    Request,
    Order,
    Authorization,
    Health
} = require("../framework");

(async () => {

    console.log("EB Platform® Test Suite");
    console.log("========================");

    const container = new Container();

    container.register("answer", 42);

    assert.strictEqual(
        container.resolve("answer"),
        42
    );

    console.log("✓ Dependency container");

    const events = new EventBus();

    let received = false;

    events.on("test", payload => {
        received = payload.value === 123;
    });

    events.emit("test", { value: 123 });

    assert.strictEqual(received, true);

    console.log("✓ Event bus");

    const commands = new CommandBus();

    commands.register(
        "add",
        ({ a, b }) => a + b
    );

    assert.strictEqual(
        await commands.execute("add", { a: 2, b: 3 }),
        5
    );

    console.log("✓ Command bus");

    const queries = new QueryBus();

    queries.register(
        "answer",
        () => ({ answer: 42 })
    );

    assert.deepStrictEqual(
        await queries.execute("answer"),
        { answer: 42 }
    );

    console.log("✓ Query bus");

    const entity = new Entity({
        name: "test"
    });

    assert.ok(entity.id);
    assert.ok(entity.createdAt);

    console.log("✓ Entity system");

    const request = new Request({
        customerId: "customer-1"
    });

    assert.strictEqual(
        request.status,
        "pending"
    );

    request.transition("accepted");

    assert.strictEqual(
        request.status,
        "accepted"
    );

    console.log("✓ Request domain");

    const order = new Order({
        requestId: request.id,
        total: 25
    });

    assert.strictEqual(order.total, 25);

    console.log("✓ Order domain");

    const auth = new Authorization();

    auth.grant(
        "operations",
        "request.manage"
    );

    assert.strictEqual(
        auth.allows(
            "operations",
            "request.manage"
        ),
        true
    );

    console.log("✓ Authorization");

    const health = new Health();

    health.register(
        "test",
        async () => ({ test: true })
    );

    const healthResult = await health.check();

    assert.strictEqual(
        healthResult.status,
        "ok"
    );

    console.log("✓ Health subsystem");

    const app = new Application();

    app.module({
        name: "test-module",

        async initialize(application) {
            application.health.register(
                "test-module",
                async () => ({ loaded: true })
            );
        }
    });

    await app.start();

    const status = await app.status();

    assert.strictEqual(status.running, true);
    assert.ok(status.modules.includes("test-module"));

    await app.stop();

    console.log("✓ Application kernel");

    console.log("");
    console.log("================================");
    console.log(" ALL PLATFORM TESTS PASSED");
    console.log("================================");

})().catch(error => {
    console.error("");
    console.error("TEST FAILURE");
    console.error(error);
    process.exit(1);
});
JS

echo
echo "[14/14] Creating architecture manifest..."

cat > "$DOCS/ARCHITECTURE.md" <<'DOC'
# EB Platform® Architecture

Request Runner® is the first application built on EB Platform®.

## Principles

1. Additive evolution.
2. Stable contracts.
3. Platform-independent application logic.
4. Infrastructure adapters rather than application rewrites.
5. One authoritative runtime boundary.
6. Modules are independently extensible.
7. Data persistence is abstracted.
8. Realtime is abstracted.
9. Security is centralized.
10. Observability is built into the platform.
11. Deployment topology does not dictate domain architecture.
12. Existing working application code is preserved during migration.

## Core

- Runtime
- Dependency container
- Module registry
- Command bus
- Query bus
- Event bus
- Middleware
- Error model

## Domain

- Customers
- Requests
- Orders
- Dispatch
- Drivers
- Locations
- Scheduling
- Payments
- Notifications
- Operations
- Administration

## Infrastructure

Current Android/Termux compatibility is retained through the existing
Webpack-based Next.js launcher.

Future deployment environments are adapters around the same application
contracts.

## Scaling Model

The platform can evolve from:

single process

to:

multi-process

to:

worker pools

to:

distributed services

to:

regional infrastructure

without requiring the domain layer to be rewritten.
DOC

cat > "$DOCS/PLATFORM-RULES.md" <<'DOC'
# EB Platform® Engineering Rules

## Rule 1

Do not replace the architecture to solve an implementation problem.

## Rule 2

Fix the smallest layer responsible for the problem.

## Rule 3

Preserve working code.

## Rule 4

New functionality becomes a module, service, adapter, or extension.

## Rule 5

Business logic must not depend directly on Android, Termux, or a specific
database.

## Rule 6

Infrastructure may change without changing domain contracts.

## Rule 7

All destructive migrations require a backup.

## Rule 8

One authoritative launcher.

## Rule 9

One authoritative configuration.

## Rule 10

Tests accompany platform capabilities.

## Rule 11

Scale horizontally through contracts, events, queues, workers, and adapters.

## Rule 12

Do not introduce artificial capacity ceilings.
DOC

# Add platform package metadata without destroying existing metadata.
node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.ebPlatform = {
    name: "EB Platform®",
    version: "1.0.0",
    application: "Request Runner®",
    architecture: "foundational",
    additive: true
};

pkg.scripts = pkg.scripts || {};

pkg.scripts["eb:status"] = "node bin/status.js";
pkg.scripts["eb:doctor"] = "node bin/doctor.js";
pkg.scripts["eb:test"] = "node tests/run.js";

fs.writeFileSync(
    file,
    JSON.stringify(pkg, null, 2) + "\n"
);
NODE

echo
echo "=============================================================="
echo " BUILD VERIFICATION"
echo "=============================================================="

node --check "$FRAMEWORK/index.js"
node --check "$FRAMEWORK/core/application.js"
node --check "$FRAMEWORK/core/container/index.js"
node --check "$FRAMEWORK/core/events/event-bus.js"
node --check "$FRAMEWORK/core/commands/command-bus.js"
node --check "$FRAMEWORK/core/queries/query-bus.js"
node --check "$FRAMEWORK/core/modules/module-registry.js"
node --check "$FRAMEWORK/data/adapters/json-repository.js"
node --check "$FRAMEWORK/realtime/realtime-bus.js"
node --check "$FRAMEWORK/security/authorization.js"
node --check "$FRAMEWORK/security/audit.js"
node --check "$BIN/status.js"
node --check "$BIN/doctor.js"
node --check "$TESTS/run.js"

echo "✓ JavaScript syntax"

node "$TESTS/run.js"

echo
echo "=============================================================="
echo " EB PLATFORM® BUILD COMPLETE"
echo "=============================================================="
echo
echo "Architecture:"
echo "  $APP"
echo
echo "Framework:"
echo "  $FRAMEWORK"
echo
echo "Request Runner®:"
echo "  $APPS/request-runner"
echo
echo "CLI:"
echo "  $BIN/eb"
echo
echo "Backup:"
echo "  $BACKUP"
echo
echo "Commands:"
echo "  $BIN/eb status"
echo "  $BIN/eb doctor"
echo "  $BIN/eb test"
echo "  $BIN/eb start"
echo "  $BIN/eb stop"
echo "  $BIN/eb backup"
echo
echo "Existing Request Runner® runtime was preserved."
echo "The new platform foundation is additive."
echo "=============================================================="
