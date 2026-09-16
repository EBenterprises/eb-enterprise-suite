const Container = require("./container");
const EventBus = require("./events/event-bus");
const CommandBus = require("./commands/command-bus");
const QueryBus = require("./queries/query-bus");
const ModuleRegistry = require("./modules/module-registry");
const Pipeline = require("./middleware/pipeline");
const Health = require("../observability/health");

class Application {
    constructor() {
        this.container = new Container();
        this.events = new EventBus();
        this.commands = new CommandBus();
        this.queries = new QueryBus();
        this.modules = new ModuleRegistry();
        this.middleware = new Pipeline();
        this.health = new Health();
        this.started = false;
    }

    register(name, value) {
        this.container.register(name, value);
        return this;
    }

    module(module) {
        this.modules.register(module);
        return this;
    }

    async start() {
        if (this.started) {
            return this;
        }

        await this.modules.initialize(this);

        this.started = true;

        this.events.emit("platform.started", {
            timestamp: new Date().toISOString()
        });

        return this;
    }

    async stop() {
        if (!this.started) {
            return;
        }

        await this.modules.shutdown(this);

        this.started = false;

        this.events.emit("platform.stopped", {
            timestamp: new Date().toISOString()
        });
    }

    async status() {
        return {
            running: this.started,
            modules: this.modules.list().map(module => module.name),
            health: await this.health.check()
        };
    }
}

module.exports = Application;
