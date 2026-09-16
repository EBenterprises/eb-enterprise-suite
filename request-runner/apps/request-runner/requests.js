const requests = new Map();

const VALID_STATES = new Set([
    "created",
    "queued",
    "assigned",
    "in_progress",
    "completed",
    "cancelled",
    "failed"
]);

function normalize(input = {}) {
    if (!input || typeof input !== "object") {
        throw new Error("Request must be an object");
    }

    if (!input.id) {
        throw new Error("Request id is required");
    }

    const id = String(input.id);

    const status = input.status || "created";

    if (!VALID_STATES.has(status)) {
        throw new Error(`Invalid Request state: ${status}`);
    }

    return {
        ...input,
        id,
        status,
        createdAt: input.createdAt || new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };
}

function create(input = {}) {
    const item = normalize(input);

    if (requests.has(item.id)) {
        throw new Error(`Request already exists: ${item.id}`);
    }

    requests.set(item.id, item);

    return { ...item };
}

function get(id) {
    if (!id) {
        return null;
    }

    const item = requests.get(String(id));

    return item ? { ...item } : null;
}

function update(id, patch = {}) {
    const key = String(id);

    if (!requests.has(key)) {
        throw new Error(`Request not found: ${id}`);
    }

    let changes;

    if (typeof patch === "string") {
        changes = { status: patch };
    } else if (patch && typeof patch === "object") {
        changes = { ...patch };
    } else {
        throw new Error("Request update must be an object or state");
    }

    if (
        Object.prototype.hasOwnProperty.call(changes, "status") &&
        !VALID_STATES.has(changes.status)
    ) {
        throw new Error(`Invalid Request state: ${changes.status}`);
    }

    const current = requests.get(key);

    const updated = {
        ...current,
        ...changes,
        id: key,
        updatedAt: new Date().toISOString()
    };

    requests.set(key, updated);

    return { ...updated };
}

function remove(id) {
    return requests.delete(String(id));
}

function list() {
    return Array.from(requests.values()).map(item => ({ ...item }));
}

function clear() {
    requests.clear();
}

module.exports = {
    name: "requests",

    VALID_STATES: Object.freeze(Array.from(VALID_STATES)),

    create,
    get,
    update,
    remove,
    list,
    clear,

    async initialize(app) {
        app.health.register("requests", async () => ({
            module: "requests",
            count: requests.size
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
