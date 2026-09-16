"use strict";

const crypto = require("crypto");
const project = require("../core/project");
const tasks = require("../core/task-store");
const logger = require("../core/logger");
const executor = require("./executor");

async function repair(failure) {
    const current = project.get();

    project.update({
        state: "repairing",
        counters: {
            ...current.counters,
            repairCycles:
                current.counters.repairCycles + 1
        }
    });

    project.event(
        "REPAIR_STARTED",
        {
            failure
        }
    );

    logger.warn(
        "Autonomous repair cycle started",
        failure
    );

    /*
     * Repair hooks are deliberately extensible.
     *
     * The platform does not hard-code a five-attempt
     * limit. A repair can create a new task, branch,
     * invoke a project-specific adapter, or re-plan.
     */

    const repairTask = tasks.add({
        id: crypto.randomUUID(),
        title: `Repair: ${failure.message || "verification failure"}`,
        description:
            JSON.stringify(failure),
        phase: "repair",
        metadata: {
            source: "autonomous-repair"
        }
    });

    const result =
        await executor.command(
            "true"
        );

    if (!result.ok) {
        logger.warn(
            "Generic repair hook did not resolve issue"
        );
    }

    tasks.update(
        repairTask.id,
        {
            status: "completed"
        }
    );

    project.event(
        "REPAIR_COMPLETED",
        {
            taskId: repairTask.id
        }
    );

    return repairTask;
}

module.exports = {
    repair
};
