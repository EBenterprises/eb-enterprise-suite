"use strict";

const fs = require("fs");
const path = require("path");

const graph =
    require("./work-graph");

const planner =
    require("./planner");

const ROOT =
    path.resolve(__dirname, "..");

const LOG =
    path.join(
        ROOT,
        "logs",
        "worker.log"
    );

function log(message) {
    fs.mkdirSync(
        path.dirname(LOG),
        { recursive: true }
    );

    fs.appendFileSync(
        LOG,
        `[${new Date().toISOString()}] ${message}\n`
    );
}

function inspectProject() {
    const checks = [
        "package.json",
        "apps",
        "src",
        "app"
    ];

    return checks.filter(
        item =>
            fs.existsSync(
                path.join(
                    process.cwd(),
                    item
                )
            )
    );
}

function discover(task) {
    const found =
        inspectProject();

    log(
        `DISCOVERY:${JSON.stringify(found)}`
    );

    return found;
}

function execute(task) {
    task = graph.update(
        task.id,
        {
            state: "running",
            attempts:
                task.attempts + 1
        }
    );

    log(
        `EXECUTE:${task.id}:${task.title}`
    );

    /*
     * Execution is intentionally isolated
     * from planning.
     *
     * Real builders, shell workers,
     * test runners and LLM adapters plug
     * into this boundary.
     */

    const result = {
        success: true,
        taskId: task.id,
        discovered:
            discover(task)
    };

    if (result.success) {
        graph.update(
            task.id,
            {
                state: "verified",
                metadata: {
                    ...task.metadata,
                    execution:
                        result
                }
            }
        );

        log(
            `VERIFIED:${task.id}`
        );

        return true;
    }

    graph.update(
        task.id,
        {
            state: "failed"
        }
    );

    return false;
}

function repair(task) {
    const repair =
        graph.add({
            title:
                `Repair: ${task.title}`,

            description:
                `Diagnose and repair failed task: ${task.description}`,

            priority:
                task.priority + 1,

            dependsOn: [],

            metadata: {
                kind: "repair",
                parentId: task.id
            }
        });

    graph.update(
        task.id,
        {
            state: "repairing",
            repairs:
                task.repairs + 1
        }
    );

    log(
        `REPAIR_CREATED:${repair.id}`
    );

    return repair;
}

function runOnce() {
    let task =
        graph.next();

    if (!task) {
        return {
            state: "idle"
        };
    }

    /*
     * Expand an objective before executing
     * it. This is what permits unlimited
     * dynamically generated work.
     */

    const children =
        planner.expand(task);

    if (
        children.length > 0 &&
        task.metadata &&
        task.metadata.kind ===
            "root-objective"
    ) {
        graph.update(
            task.id,
            {
                state: "verified"
            }
        );

        log(
            `OBJECTIVE_EXPANDED:${task.id}`
        );

        return {
            state: "expanded",
            taskId: task.id,
            children:
                children.map(
                    child => child.id
                )
        };
    }

    try {
        const success =
            execute(task);

        if (!success) {
            return {
                state: "repair-required",
                task: repair(task)
            };
        }

        return {
            state: "verified",
            taskId: task.id
        };
    } catch (error) {
        log(
            `ERROR:${task.id}:${error.message}`
        );

        graph.update(
            task.id,
            {
                state: "failed",
                metadata: {
                    ...task.metadata,
                    error:
                        error.message
                }
            }
        );

        return {
            state: "failed",
            taskId: task.id
        };
    }
}

module.exports = {
    runOnce,
    discover,
    execute,
    repair
};
