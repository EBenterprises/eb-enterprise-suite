"use strict";

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const config = require("../core/config");
const project = require("../core/project");

const PID_FILE =
    path.join(config.paths.state, "engine.pid");

const LOG_FILE =
    path.join(config.paths.logs, "engine.log");

function log(message) {
    fs.mkdirSync(
        config.paths.logs,
        { recursive: true }
    );

    fs.appendFileSync(
        LOG_FILE,
        `[${new Date().toISOString()}] ${message}\n`
    );
}

function sleep(ms) {
    return new Promise(
        resolve => setTimeout(resolve, ms)
    );
}

function pidAlive(pid) {
    try {
        process.kill(pid, 0);
        return true;
    } catch (_) {
        return false;
    }
}

function acquireLock() {
    if (fs.existsSync(PID_FILE)) {
        const pid =
            Number(
                fs.readFileSync(
                    PID_FILE,
                    "utf8"
                )
            );

        if (
            Number.isInteger(pid) &&
            pid > 0 &&
            pidAlive(pid)
        ) {
            throw new Error(
                `ENGINE_ALREADY_RUNNING:${pid}`
            );
        }
    }

    fs.writeFileSync(
        PID_FILE,
        String(process.pid)
    );
}

function releaseLock() {
    try {
        fs.unlinkSync(PID_FILE);
    } catch (_) {}
}

function run(command, args = []) {
    return new Promise(resolve => {
        const child = spawn(
            command,
            args,
            {
                cwd: process.cwd(),
                stdio: [
                    "ignore",
                    "pipe",
                    "pipe"
                ]
            }
        );

        let stdout = "";
        let stderr = "";

        child.stdout.on(
            "data",
            data => {
                stdout += data.toString();
            }
        );

        child.stderr.on(
            "data",
            data => {
                stderr += data.toString();
            }
        );

        child.on(
            "close",
            code => {
                resolve({
                    code,
                    stdout,
                    stderr
                });
            }
        );

        child.on(
            "error",
            error => {
                resolve({
                    code: -1,
                    stdout,
                    stderr:
                        stderr +
                        "\n" +
                        error.message
                });
            }
        );
    });
}

async function cycle() {
    const current =
        project.get();

    if (!current) {
        log("IDLE:NO_PROJECT");
        return false;
    }

    if (
        current.state ===
        "completed"
    ) {
        log("PROJECT_ALREADY_COMPLETE");
        return false;
    }

    /*
     * This is deliberately a durable
     * control loop. Future workers plug
     * into this loop rather than creating
     * another manual continuation script.
     */

    project.event(
        "engine_cycle",
        {
            state:
                current.state
        }
    );

    switch (current.state) {
        case "received":
            project.update({
                state: "planning"
            });

            log("TRANSITION:planning");
            return true;

        case "planning":
            project.update({
                state: "ready"
            });

            log("TRANSITION:ready");
            return true;

        case "ready":
            project.update({
                state: "executing"
            });

            log("TRANSITION:executing");
            return true;

        case "executing":
            project.update({
                state: "verifying"
            });

            log("TRANSITION:verifying");
            return true;

        case "verifying":
            project.update({
                state: "repairing"
            });

            log("TRANSITION:repairing");
            return true;

        case "repairing":
            project.update({
                state: "executing"
            });

            log("TRANSITION:executing");
            return true;

        default:
            log(
                `UNKNOWN_STATE:${current.state}`
            );

            project.update({
                state: "planning"
            });

            return true;
    }
}

async function start() {
    acquireLock();

    process.on(
        "exit",
        releaseLock
    );

    process.on(
        "SIGINT",
        () => {
            releaseLock();
            process.exit(130);
        }
    );

    process.on(
        "SIGTERM",
        () => {
            releaseLock();
            process.exit(143);
        }
    );

    log("ENGINE_STARTED");

    while (true) {
        try {
            const active =
                await cycle();

            if (!active) {
                await sleep(5000);
            } else {
                await sleep(1000);
            }
        } catch (error) {
            log(
                `ENGINE_ERROR:${error.message}`
            );

            /*
             * Never terminate the autonomous
             * engine merely because one worker
             * failed. Persist the failure and
             * retry through the control loop.
             */

            try {
                project.event(
                    "engine_error",
                    {
                        error:
                            error.message
                    }
                );
            } catch (_) {}

            await sleep(3000);
        }
    }
}

start().catch(error => {
    log(
        `FATAL:${error.message}`
    );

    releaseLock();
    process.exit(1);
});
