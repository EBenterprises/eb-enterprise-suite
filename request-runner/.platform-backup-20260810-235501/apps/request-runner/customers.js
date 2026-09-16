module.exports = {
    name: "customers",

    async initialize(app) {
        app.health.register("customers", async () => ({
            module: "customers"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
