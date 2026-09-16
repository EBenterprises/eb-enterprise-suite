"use strict";

const fs = require("fs");
const path = require("path");

const worker =
    require("./worker");

const graph =
    require("./work-graph");

const ROOT =
    path.resolve(__dirname, "..");

const PID =
    path.join(
        ROOT,
        "state",
        "worker.pid"
    );

function sleep(ms) {
    return new Promise(
        resolve =>
            setTimeout(resolve, ms)
    );
}

function acquire() {
    if (fs.existsSync(PID)) {
        const old =
            Number(
                fs.readFileSync(
                    PID,
                    "utf8"
                )
            );

        if (old) {
            try {
                process.kill(old, 0);
                throw new Error(
                    "WORKER_ALREADY_RUNNING"
                );
            } catch (error) {
                if (
                    error.message ===
                    "WORKER_ALREADY_RUNNING"
                ) {
                    throw error;
                }
            }
        }
    }

    fs.writeFileSync(
        PID,
        String(process.pid)
    );
}

function release() {
    try {
        fs.unlinkSync(PID);
    } catch (_) {}
}

async function main() {
    acquire();

    process.on(
        "exit",
        release
    );

    process.on(
        "SIGTERM",
        () => {
            release();
            process.exit(143);
        }
    );

    process.on(
        "SIGINT",
        () => {
            release();
            process.exit(130);
        }
    );

    while (true) {
        try {
            const result =
                worker.runOnce();

            if (
                result.state ===
                "idle"
            ) {
                await sleep(3000);
            } else {
                await sleep(500);
            }

            const summary =
                graph.summary();

            if (
                summary.total > 0 &&
                summary.verified ===
                    summary.total
            ) {
                /*
                 * Do not terminate permanently.
                 * Future work can be added to
                 * the graph.
                 */
                await sleep(3000);
            }
        } catch (error) {
            console.error(
                "WORKER:",
                error.message
            );

            await sleep(3000);
        }
    }
}

main().catch(error => {
    console.error(
        error.message
    );

    release();
    process.exit(1);
});
