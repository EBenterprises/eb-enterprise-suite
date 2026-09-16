"use strict";

const fs = require("fs");
const path = require("path");
const config = require("../core/config");
const executor = require("./executor");
const logger = require("../core/logger");

async function verify() {
    const checks = [];

    checks.push({
        name: "Project state exists",
        ok: fs.existsSync(
            path.join(config.paths.state, "project.json")
        )
    });

    checks.push({
        name: "Task state exists",
        ok: fs.existsSync(
            path.join(config.paths.state, "tasks.json")
        )
    });

    const packageCheck =
        await executor.command(
            "test -f package.json"
        );

    checks.push({
        name: "Package manifest",
        ok: packageCheck.ok
    });

    const failed =
        checks.filter(check => !check.ok);

    logger.info(
        "Verification completed",
        {
            checks,
            failed: failed.length
        }
    );

    return {
        ok: failed.length === 0,
        checks,
        failed
    };
}

module.exports = {
    verify
};
