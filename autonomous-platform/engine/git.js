"use strict";

const executor = require("./executor");
const logger = require("../core/logger");

async function available() {
    const result =
        await executor.command(
            "git rev-parse --is-inside-work-tree"
        );

    return result.ok;
}

async function checkpoint(label) {
    if (!(await available())) {
        return {
            ok: false,
            reason: "not-a-git-worktree"
        };
    }

    await executor.command(
        "git add -A"
    );

    const status =
        await executor.command(
            "git status --porcelain"
        );

    if (!status.stdout.trim()) {
        return {
            ok: true,
            changed: false
        };
    }

    const safe =
        label
            .replace(/[^a-zA-Z0-9._-]+/g, "-")
            .slice(0, 100);

    const commit =
        await executor.command(
            `git commit -m "Autonomous checkpoint: ${safe}"`
        );

    logger.info(
        "Git checkpoint",
        {
            label: safe,
            ok: commit.ok
        }
    );

    return {
        ok: commit.ok,
        changed: true
    };
}

async function branch(name) {
    if (!(await available())) {
        return {
            ok: false,
            reason: "not-a-git-worktree"
        };
    }

    const safe =
        name
            .replace(/[^a-zA-Z0-9._/-]+/g, "-")
            .slice(0, 100);

    return executor.command(
        `git switch -c "${safe}"`
    );
}

module.exports = {
    available,
    checkpoint,
    branch
};
