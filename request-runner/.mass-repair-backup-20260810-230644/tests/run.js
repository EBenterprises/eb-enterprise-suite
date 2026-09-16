const assert = require("assert");

const {
    Application,
    Container,
    EventBus,
    CommandBus,
    QueryBus,
    JsonRepository,
    Entity,
    Request,
    Order,
    Authorization,
    Health
} = require("../framework");

(async () => {

    console.log("EB Platform® Test Suite");
    console.log("========================");

    const container = new Container();

    container.register("answer", 42);

    assert.strictEqual(
        container.resolve("answer"),
        42
    );

    console.log("✓ Dependency container");

    const events = new EventBus();

    let received = false;

    events.on("test", payload => {
        received = payload.value === 123;
    });

    events.emit("test", { value: 123 });

    assert.strictEqual(received, true);

    console.log("✓ Event bus");

    const commands = new CommandBus();

    commands.register(
        "add",
        ({ a, b }) => a + b
    );

    assert.strictEqual(
        await commands.execute("add", { a: 2, b: 3 }),
        5
    );

    console.log("✓ Command bus");

    const queries = new QueryBus();

    queries.register(
        "answer",
        () => ({ answer: 42 })
    );

    assert.deepStrictEqual(
        await queries.execute("answer"),
        { answer: 42 }
    );

    console.log("✓ Query bus");

    const entity = new Entity({
        name: "test"
    });

    assert.ok(entity.id);
    assert.ok(entity.createdAt);

    console.log("✓ Entity system");

    const request = new Request({
        customerId: "customer-1"
    });

    assert.strictEqual(
        request.status,
        "pending"
    );

    request.transition("accepted");

    assert.strictEqual(
        request.status,
        "accepted"
    );

    console.log("✓ Request domain");

    const order = new Order({
        requestId: request.id,
        total: 25
    });

    assert.strictEqual(order.total, 25);

    console.log("✓ Order domain");

    const auth = new Authorization();

    auth.grant(
        "operations",
        "request.manage"
    );

    assert.strictEqual(
        auth.allows(
            "operations",
            "request.manage"
        ),
        true
    );

    console.log("✓ Authorization");

    const health = new Health();

    health.register(
        "test",
        async () => ({ test: true })
    );

    const healthResult = await health.check();

    assert.strictEqual(
        healthResult.status,
        "ok"
    );

    console.log("✓ Health subsystem");

    const app = new Application();

    app.module({
        name: "test-module",

        async initialize(application) {
            application.health.register(
                "test-module",
                async () => ({ loaded: true })
            );
        }
    });

    await app.start();

    const status = await app.status();

    assert.strictEqual(status.running, true);
    assert.ok(status.modules.includes("test-module"));

    await app.stop();

    console.log("✓ Application kernel");

    console.log("");
    console.log("================================");
    console.log(" ALL PLATFORM TESTS PASSED");
    console.log("================================");

})().catch(error => {
    console.error("");
    console.error("TEST FAILURE");
    console.error(error);
    process.exit(1);
});
