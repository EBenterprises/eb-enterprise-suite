module.exports = {
    name: "drivers",

    async initialize(app) {
        app.health.register("drivers", async () => ({
            module: "drivers"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
