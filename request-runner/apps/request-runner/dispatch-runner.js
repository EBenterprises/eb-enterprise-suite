"use strict";

/**
 * Request Runner® — Dispatch® Runner Selection
 *
 * Selects an available Runner® for a Request®.
 * Transportation method is not a dispatch requirement.
 */

const runners = require("./runners");

function scoreRunner(runner, request = {}) {
    let score = 0;

    if (
        Array.isArray(request.capabilities) &&
        request.capabilities.length > 0
    ) {
        for (const capability of request.capabilities) {
            if (runner.capabilities.includes(capability)) {
                score += 10;
            }
        }
    }

    if (runner.location && request.location) {
        score += 1;
    }

    return score;
}

function select(request = {}) {
    const available = runners.available();

    if (available.length === 0) {
        return null;
    }

    return available
        .map(runner => ({
            runner,
            score: scoreRunner(runner, request)
        }))
        .sort((a, b) => b.score - a.score)[0]
        .runner;
}

function dispatch(requestId, request = {}) {
    if (!requestId) {
        throw new Error("Request id is required");
    }

    const runner = select(request);

    if (!runner) {
        throw new Error("No available Runner");
    }

    runners.setUnavailable(runner.id, String(requestId));

    return {
        requestId: String(requestId),
        runnerId: runner.id,
        status: "dispatched",
        dispatchedAt: new Date().toISOString()
    };
}

function release(runnerId) {
    return runners.setAvailable(runnerId);
}

module.exports = {
    select,
    dispatch,
    release
};
