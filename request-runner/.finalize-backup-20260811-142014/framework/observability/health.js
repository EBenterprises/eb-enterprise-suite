class Health {
    constructor() {
        this.checks = new Map();
    }

    register(name, check) {
        this.checks.set(name, check);
    }

    async check() {
        const results = {};

        for (const [name, check] of this.checks) {
            try {
                const result = await check();

                results[name] = {
                    status: "ok",
                    ...(result || {})
                };
            } catch (error) {
                results[name] = {
                    status: "error",
                    error: error.message
                };
            }
        }

        const failed = Object.values(results)
            .some(result => result.status !== "ok");

        return {
            status: failed ? "degraded" : "ok",
            timestamp: new Date().toISOString(),
            checks: results
        };
    }
}

module.exports = Health;
