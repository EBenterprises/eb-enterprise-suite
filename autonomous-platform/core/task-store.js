"use strict";

const crypto = require("crypto");
const store = require("./store");

function id() {
    return crypto.randomUUID();
}

function load() {
    return store.read("tasks", []);
}

function save(tasks) {
    store.write("tasks", tasks);
}

function add(task) {
    const tasks = load();

    const record = {
        id: task.id || id(),
        title: task.title,
        description: task.description || "",
        phase: task.phase || "build",
        status: task.status || "pending",
        attempts: task.attempts || 0,
        repairs: task.repairs || 0,
        dependencies: task.dependencies || [],
        verification: task.verification || [],
        createdAt: task.createdAt || new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        metadata: task.metadata || {}
    };

    tasks.push(record);
    save(tasks);

    return record;
}

function update(taskId, patch) {
    const tasks = load();
    const index = tasks.findIndex(
        task => task.id === taskId
    );

    if (index === -1) {
        throw new Error(
            `Task not found: ${taskId}`
        );
    }

    tasks[index] = {
        ...tasks[index],
        ...patch,
        updatedAt: new Date().toISOString()
    };

    save(tasks);

    return tasks[index];
}

function get(taskId) {
    return load().find(
        task => task.id === taskId
    ) || null;
}

function next() {
    const tasks = load();

    return tasks.find(task =>
        task.status === "pending" &&
        dependenciesSatisfied(task, tasks)
    ) || null;
}

function dependenciesSatisfied(task, tasks) {
    return task.dependencies.every(dep => {
        const found = tasks.find(
            candidate => candidate.id === dep
        );

        return found && found.status === "completed";
    });
}

module.exports = {
    load,
    save,
    add,
    update,
    get,
    next
};
