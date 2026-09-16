module.exports = {
    name: "scheduling",

    async initialize(app) {
        app.health.register("scheduling", async () => ({
            module: "scheduling"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
