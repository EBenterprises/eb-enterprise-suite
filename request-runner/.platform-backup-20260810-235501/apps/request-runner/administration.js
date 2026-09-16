module.exports = {
    name: "administration",

    async initialize(app) {
        app.health.register("administration", async () => ({
            module: "administration"
        }));
    },

    async shutdown() {
        // Module shutdown hook.
    }
};
