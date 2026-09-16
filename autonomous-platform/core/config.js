"use strict";

const path = require("path");

const ROOT = path.resolve(__dirname, "..");

module.exports = {
    ROOT,

    paths: {
        state: path.join(ROOT, "state"),
        plans: path.join(ROOT, "plans"),
        logs: path.join(ROOT, "logs"),
        adapters: path.join(ROOT, "adapters"),
        plugins: path.join(ROOT, "plugins"),
        worktrees: path.join(ROOT, "worktrees"),
        artifacts: path.join(ROOT, "artifacts"),
        checkpoints: path.join(ROOT, "checkpoints"),
        policies: path.join(ROOT, "policies")
    },

    autonomous: true,
    continuous: true,
    persistent: true,
    selfRepair: true,
    selfVerify: true,
    autoPlan: true,
    autoReplan: true,
    autoBranch: true,
    autoCheckpoint: true,
    autoResume: true,

    neverRequireContinue: true,

    completion: {
        requireBuild: true,
        requireTests: true,
        requireVerification: true,
        requireDeployment: true,
        requireHealthCheck: true
    }
};
