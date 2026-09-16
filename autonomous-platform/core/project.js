"use strict";

const crypto = require("crypto");
const store = require("./store");

function create(request) {
    const project = {
        id: crypto.randomUUID(),
        request,
        state: "received",

        createdAt:
            new Date().toISOString(),

        updatedAt:
            new Date().toISOString(),

        requirements: [],
        tasks: [],
        blockers: [],
        history: [],

        counters: {
            plans: 0,
            builds: 0,
            tests: 0,
            repairs: 0,
            deployments: 0,
            verifications: 0
        }
    };

    store.write(
        "project",
        project
    );

    return project;
}

function get() {
    return store.read(
        "project",
        null
    );
}

function update(patch) {
    const current = get();

    if (!current) {
        throw new Error(
            "No active project"
        );
    }

    const next = {
        ...current,
        ...patch,
        updatedAt:
            new Date().toISOString()
    };

    store.write(
        "project",
        next
    );

    return next;
}

function event(type, data = {}) {
    const current = get();

    if (!current) {
        throw new Error(
            "No active project"
        );
    }

    current.history.push({
        id: crypto.randomUUID(),
        type,
        data,
        timestamp:
            new Date().toISOString()
    });

    current.updatedAt =
        new Date().toISOString();

    store.write(
        "project",
        current
    );
}

module.exports = {
    create,
    get,
    update,
    event
};
