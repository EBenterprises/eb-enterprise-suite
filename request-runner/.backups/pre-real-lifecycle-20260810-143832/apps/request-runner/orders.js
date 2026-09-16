module.exports = {
    name: "orders",

    async initialize(app) {
        app.health.register("orders", async () => ({
            module: "orders"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
