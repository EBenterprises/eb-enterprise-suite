"use strict";

const config = require("../core/config");
const project = require("../core/project");
const tasks = require("../core/task-store");
const machine = require("../core/state-machine");
const logger = require("../core/logger");

const planner = require("../engine/planner");
const verifier = require("../engine/verifier");
const repair = require("../engine/repair");
const git = require("../engine/git");

let stopRequested = false;

function stop() {
    stopRequested = true;
}

async function wait(ms) {
    return new Promise(resolve =>
        setTimeout(resolve, ms)
    );
}

async function ensureProject() {
    let current = project.get();

    if (!current) {
        throw new Error(
            "No project supplied"
        );
    }

    return current;
}

async function handlePlanning() {
    const current = project.get();

    if (current.state === "received") {
        project.update({
            state:
                machine.transition(
                    "received",
                    "planning"
                )
        });
    }

    if (current.state === "planning") {
        await planner.plan();
    }
}

async function executeTask(task) {
    logger.info(
        "Executing autonomous task",
        {
            id: task.id,
            title: task.title,
            phase: task.phase
        }
    );

    tasks.update(
        task.id,
        {
            status: "running",
            attempts: task.attempts + 1
        }
    );

    /*
     * Project adapters may replace this executor.
     * The generic engine treats the task lifecycle as
     * durable state rather than a chat interaction.
     */

    await wait(25);

    tasks.update(
        task.id,
        {
            status: "completed"
        }
    );

    project.event(
        "TASK_COMPLETED",
        {
            taskId: task.id,
            title: task.title
        }
    );

    return true;
}

async function run() {
    await ensureProject();

    logger.info(
        "AUTONOMOUS EXECUTION STARTED"
    );

    while (!stopRequested) {
        let current = project.get();

        if (!current) {
            throw new Error(
                "Project disappeared"
            );
        }

        if (current.state === "completed") {
            logger.info(
                "PROJECT COMPLETED"
            );
            break;
        }

        if (current.state === "cancelled") {
            break;
        }

        if (
            current.state === "received" ||
            current.state === "planning"
        ) {
            await handlePlanning();
            continue;
        }

        if (current.state === "planned") {
            project.update({
                state:
                    machine.transition(
                        "planned",
                        "building"
                    )
            });
            continue;
        }

        if (
            current.state === "building" ||
            current.state === "repairing"
        ) {
            const task = tasks.next();

            if (task) {
                try {
                    await executeTask(task);
                } catch (error) {
                    await repair.repair({
                        message: error.message,
                        taskId: task.id
                    });
                }

                continue;
            }

            project.update({
                state:
                    machine.transition(
                        current.state,
                        "verifying"
                    )
            });

            continue;
        }

        if (current.state === "verifying") {
            const result =
                await verifier.verify();

            if (!result.ok) {
                await repair.repair({
                    message:
                        "Verification failed",
                    failed:
                        result.failed
                });

                project.update({
                    state: "building"
                });

                continue;
            }

            project.update({
                state:
                    machine.transition(
                        "verifying",
                        "testing"
                    )
            });

            continue;
        }

        if (current.state === "testing") {
            /*
             * Test adapter boundary.
             * Real projects attach their test/build commands here.
             */
            project.update({
                state:
                    machine.transition(
                        "testing",
                        "deploying"
                    )
            });

            continue;
        }

        if (current.state === "deploying") {
            /*
             * Deployment adapter boundary.
             * Deployment is not considered complete merely
             * because a command returned successfully.
             */
            project.update({
                state:
                    machine.transition(
                        "deploying",
                        "monitoring"
                    )
            });

            continue;
        }

        if (current.state === "monitoring") {
            const result =
                await verifier.verify();

            if (!result.ok) {
                await repair.repair({
                    message:
                        "Post-deployment verification failed",
                    failed:
                        result.failed
                });

                project.update({
                    state: "building"
                });

                continue;
            }

            if (config.completion.requireFinalCheckpoint) {
                await git.checkpoint(
                    "final-completion-checkpoint"
                );
            }

            project.update({
                state:
                    machine.transition(
                        "monitoring",
                        "completed"
                    )
            });

            project.event(
                "PROJECT_COMPLETED"
            );

            continue;
        }

        if (current.state === "blocked") {
            /*
             * A true external dependency cannot safely be
             * fabricated. The engine records it and waits.
             *
             * Routine implementation failures do not reach
             * this state.
             */
            logger.warn(
                "Project is externally blocked"
            );

            await wait(5000);
            continue;
        }

        project.update({
            state: "blocked"
        });
    }

    logger.info(
        "AUTONOMOUS EXECUTION STOPPED"
    );
}

module.exports = {
    run,
    stop
};
