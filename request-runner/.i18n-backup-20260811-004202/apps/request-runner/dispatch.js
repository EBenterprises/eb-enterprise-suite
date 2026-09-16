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
