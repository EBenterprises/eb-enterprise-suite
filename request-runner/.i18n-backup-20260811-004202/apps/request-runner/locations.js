module.exports = {
    name: "locations",

    async initialize(app) {
        app.health.register("locations", async () => ({
            module: "locations"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
