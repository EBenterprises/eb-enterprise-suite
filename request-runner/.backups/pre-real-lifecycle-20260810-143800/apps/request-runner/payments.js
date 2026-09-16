module.exports = {
    name: "payments",

    async initialize(app) {
        app.health.register("payments", async () => ({
            module: "payments"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
