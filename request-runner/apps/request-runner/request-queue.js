"use strict";

/**
 * Request Runner® — Request Queue®
 *
 * In-memory orchestration layer for queued Requests®.
 * Persistence is intentionally separate.
 */

const queue = [];

function normalize(request = {}) {
    if (!request.id) {
        throw new Error("Request id is required");
    }

    return {
        id: String(request.id),
        priority: Number.isFinite(request.priority)
            ? request.priority
            : 0,
        capabilities: Array.isArray(request.capabilities)
            ? [...request.capabilities]
            : [],
        location: request.location || null,
        createdAt: request.createdAt || new Date().toISOString()
    };
}

function enqueue(request) {
    const item = normalize(request);

    if (queue.some(existing => existing.id === item.id)) {
        throw new Error(`Request already queued: ${item.id}`);
    }

    queue.push(item);

    queue.sort((a, b) => {
        if (b.priority !== a.priority) {
            return b.priority - a.priority;
        }

        return new Date(a.createdAt) - new Date(b.createdAt);
    });

    return { ...item };
}

function peek() {
    return queue.length ? { ...queue[0] } : null;
}

function dequeue() {
    return queue.length ? { ...queue.shift() } : null;
}

function get(id) {
    const item = queue.find(request => request.id === String(id));
    return item ? { ...item } : null;
}

function remove(id) {
    const index = queue.findIndex(
        request => request.id === String(id)
    );

    if (index === -1) {
        return false;
    }

    queue.splice(index, 1);
    return true;
}

function list() {
    return queue.map(request => ({ ...request }));
}

function size() {
    return queue.length;
}

function clear() {
    queue.length = 0;
}

module.exports = {
    enqueue,
    peek,
    dequeue,
    get,
    remove,
    list,
    size,
    clear
};
