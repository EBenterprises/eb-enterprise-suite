module.exports = {
    name: "dispatch",

    async initialize(app) {
        app.health.register("dispatch", async () => ({
            module: "dispatch"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};


/*
 * Dispatch® assignment operation.
 * Coordinates an isolated Request® with a Runner®.
 */
module.exports.assign = function assign(input, runnerIdArg) {
    const app = require("./index");

    const queue = app.requestQueue || app.queue || app.requestsQueue;
    const runners = app.runners;
    const state = app.dispatchState;

    let requestId;
    let runnerId;

    if (input && typeof input === "object") {
        requestId =
            input.requestId ||
            input.id ||
            (input.request && (input.request.id || input.request.requestId));

        runnerId =
            input.runnerId ||
            (input.runner && input.runner.id);
    } else {
        requestId = input;
        runnerId = runnerIdArg;
    }

    if (!requestId) {
        throw new Error("Dispatch® requires a Request® identifier");
    }

    if (!runnerId) {
        throw new Error("Dispatch® requires a Runner® identifier");
    }

    if (!runners || typeof runners.get !== "function") {
        throw new Error("Runner® registry unavailable");
    }

    const runner = runners.get(runnerId);

    if (!runner) {
        throw new Error("Runner® not found");
    }

    if (runner.status !== "available") {
        throw new Error("Runner® is not available");
    }

    if (typeof runners.setUnavailable === "function") {
        runners.setUnavailable(runnerId, requestId);
    } else if (typeof runners.setBusy === "function") {
        runners.setBusy(runnerId, requestId);
    } else {
        throw new Error("Runner® assignment operation unavailable");
    }

    if (state && typeof state.create === "function") {
        try {
            state.create({
                id: requestId,
                requestId,
                runnerId,
                status: "assigned"
            });
        } catch (_) {
            /* Existing state may already represent this assignment. */
        }
    }

    if (queue && typeof queue.remove === "function") {
        try {
            queue.remove(requestId);
        } catch (_) {
            /* Queue removal is best-effort for isolated orchestration. */
        }
    }

    return {
        requestId,
        runnerId,
        status: "assigned"
    };
};
