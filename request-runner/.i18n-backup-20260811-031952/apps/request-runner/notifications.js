module.exports = {
    name: "notifications",

    async initialize(app) {
        app.health.register("notifications", async () => ({
            module: "notifications"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
