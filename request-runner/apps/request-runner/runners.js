"use strict";

/**
 * Request Runner® — Runner Registry
 *
 * Runner® is the universal fulfillment role.
 * Transportation method is intentionally NOT required.
 */

const runners = new Map();

function normalizeRunner(input = {}) {
    if (!input.id) {
        throw new Error("Runner id is required");
    }

    return {
        id: String(input.id),
        name: input.name ? String(input.name) : `Runner ${input.id}`,
        status: input.status || "available",
        currentRequestId: input.currentRequestId || null,
        location: input.location || null,
        capabilities: Array.isArray(input.capabilities)
            ? [...input.capabilities]
            : [],
        createdAt: input.createdAt || new Date().toISOString(),
        updatedAt: new Date().toISOString()
    };
}

function register(input) {
    const runner = normalizeRunner(input);
    runners.set(runner.id, runner);
    return { ...runner };
}

function update(id, patch = {}) {
    const existing = runners.get(String(id));

    if (!existing) {
        throw new Error(`Runner not found: ${id}`);
    }

    const updated = normalizeRunner({
        ...existing,
        ...patch,
        id: existing.id
    });

    runners.set(updated.id, updated);
    return { ...updated };
}

function setAvailable(id) {
    return update(id, {
        status: "available",
        currentRequestId: null
    });
}

function setUnavailable(id, requestId = null) {
    return update(id, {
        status: "busy",
        currentRequestId: requestId
    });
}

function remove(id) {
    return runners.delete(String(id));
}

function get(id) {
    const runner = runners.get(String(id));
    return runner ? { ...runner } : null;
}

function list() {
    return [...runners.values()].map(runner => ({ ...runner }));
}

function available() {
    return list().filter(runner => runner.status === "available");
}

function countAvailable() {
    return available().length;
}

module.exports = {
    register,
    update,
    setAvailable,
    setUnavailable,
    remove,
    get,
    list,
    available,
    countAvailable
};
