"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT =
    path.resolve(__dirname, "..");

const FILE =
    path.join(
        ROOT,
        "state",
        "work-graph.json"
    );

const STATES = Object.freeze([
    "discovered",
    "ready",
    "running",
    "blocked",
    "failed",
    "repairing",
    "verified",
    "complete"
]);

function load() {
    if (!fs.existsSync(FILE)) {
        return {
            version: 1,
            updatedAt: new Date().toISOString(),
            tasks: []
        };
    }

    try {
        return JSON.parse(
            fs.readFileSync(FILE, "utf8")
        );
    } catch (_) {
        return {
            version: 1,
            updatedAt: new Date().toISOString(),
            tasks: []
        };
    }
}

function save(graph) {
    graph.updatedAt =
        new Date().toISOString();

    const tmp = FILE + ".tmp";

    fs.writeFileSync(
        tmp,
        JSON.stringify(graph, null, 2)
    );

    fs.renameSync(tmp, FILE);

    return graph;
}

function add(input = {}) {
    const graph = load();

    const task = {
        id: input.id ||
            crypto.randomUUID(),

        title:
            input.title ||
            "Untitled task",

        description:
            input.description || "",

        state:
            input.state ||
            "discovered",

        priority:
            Number.isFinite(input.priority)
                ? input.priority
                : 50,

        dependsOn:
            Array.isArray(input.dependsOn)
                ? [...input.dependsOn]
                : [],

        attempts: 0,
        repairs: 0,

        createdAt:
            new Date().toISOString(),

        updatedAt:
            new Date().toISOString(),

        metadata:
            input.metadata || {}
    };

    graph.tasks.push(task);

    save(graph);

    return task;
}

function get(id) {
    return load().tasks.find(
        task => task.id === id
    ) || null;
}

function update(id, patch = {}) {
    const graph = load();

    const index =
        graph.tasks.findIndex(
            task => task.id === id
        );

    if (index < 0) {
        throw new Error(
            `Task not found: ${id}`
        );
    }

    const current =
        graph.tasks[index];

    if (
        patch.state &&
        !STATES.includes(patch.state)
    ) {
        throw new Error(
            `Invalid task state: ${patch.state}`
        );
    }

    graph.tasks[index] = {
        ...current,
        ...patch,
        id: current.id,
        updatedAt:
            new Date().toISOString()
    };

    save(graph);

    return graph.tasks[index];
}

function dependenciesSatisfied(
    task,
    graph
) {
    return task.dependsOn.every(
        id => {
            const dependency =
                graph.tasks.find(
                    candidate =>
                        candidate.id === id
                );

            return dependency &&
                dependency.state ===
                    "verified";
        }
    );
}

function next() {
    const graph = load();

    const candidates =
        graph.tasks.filter(task =>
            (
                task.state ===
                    "discovered" ||
                task.state ===
                    "ready"
            ) &&
            dependenciesSatisfied(
                task,
                graph
            )
        );

    candidates.sort(
        (a, b) =>
            b.priority - a.priority
    );

    return candidates[0] || null;
}

function list() {
    return load().tasks;
}

function summary() {
    const tasks = list();

    const result = {};

    for (const state of STATES) {
        result[state] =
            tasks.filter(
                task =>
                    task.state === state
            ).length;
    }

    result.total = tasks.length;

    return result;
}

module.exports = {
    STATES,
    add,
    get,
    update,
    next,
    list,
    summary
};
