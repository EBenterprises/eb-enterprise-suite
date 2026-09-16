module.exports = {
    name: "operations",

    async initialize(app) {
        app.health.register("operations", async () => ({
            module: "operations"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
