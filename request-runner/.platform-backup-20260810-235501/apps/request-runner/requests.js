module.exports = {
    name: "requests",

    async initialize(app) {
        app.health.register("requests", async () => ({
            module: "requests"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
