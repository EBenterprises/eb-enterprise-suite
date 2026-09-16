const states = new Map();

const VALID_STATES = Object.freeze([
    "queued",
    "assigned",
    "in_progress",
    "completed",
    "cancelled",
    "failed"
]);

function normalize(requestId, input = {}) {
    if (!requestId) {
        throw new Error("Request id is required");
    }

    if (!input || typeof input !== "object") {
        throw new Error("Dispatch state must be an object");
    }

    const status = input.status || "queued";

    if (!VALID_STATES.includes(status)) {
        throw new Error(`Invalid Dispatch state: ${status}`);
    }

    return {
        ...input,
        requestId: String(requestId),
        status,
        runnerId:
            input.runnerId === undefined
                ? null
                : input.runnerId,
        createdAt:
            input.createdAt ||
            new Date().toISOString(),
        updatedAt:
            new Date().toISOString()
    };
}

function create(requestId, input = {}) {
    const id = String(requestId);

    if (states.has(id)) {
        throw new Error(`Dispatch state already exists: ${id}`);
    }

    const state = normalize(id, input);

    states.set(id, state);

    return { ...state };
}

function get(requestId) {
    if (!requestId) {
        return null;
    }

    const state = states.get(String(requestId));

    return state ? { ...state } : null;
}

function update(requestId, patch = {}) {
    const id = String(requestId);

    if (!states.has(id)) {
        throw new Error(`Dispatch state not found: ${requestId}`);
    }

    const current = states.get(id);

    let changes;

    if (typeof patch === "string") {
        changes = {
            status: patch
        };
    } else if (patch && typeof patch === "object") {
        changes = {
            ...patch
        };
    } else {
        throw new Error(
            "Dispatch state update must be an object or state"
        );
    }

    if (
        Object.prototype.hasOwnProperty.call(
            changes,
            "status"
        ) &&
        !VALID_STATES.includes(changes.status)
    ) {
        throw new Error(
            `Invalid Dispatch state: ${changes.status}`
        );
    }

    const updated = {
        ...current,
        ...changes,
        requestId: id,
        updatedAt: new Date().toISOString()
    };

    states.set(id, updated);

    return { ...updated };
}

function remove(requestId) {
    return states.delete(String(requestId));
}

function list() {
    return Array.from(states.values()).map(
        state => ({ ...state })
    );
}

function clear() {
    states.clear();
}

module.exports = {
    name: "dispatch-state",
    VALID_STATES,
    create,
    get,
    update,
    remove,
    list,
    clear
};
