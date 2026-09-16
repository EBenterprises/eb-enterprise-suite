const {
    Application,
    environment
} = require("../framework");

const app = new Application();

(async () => {
    const modules = require("../apps/request-runner");

    for (const module of modules) {
        app.module(module);
    }

    await app.start();

    const status = await app.status();

    console.log(JSON.stringify({
        platform: "EB Platform®",
        application: "Request Runner®",
        environment: environment.detectEnvironment(),
        ...status
    }, null, 2));

    await app.stop();
})().catch(error => {
    console.error(error);
    process.exit(1);
});
