class CommandBus {
    constructor() {
        this.handlers = new Map();
    }

    register(command, handler) {
        if (this.handlers.has(command)) {
            throw new Error(`Command already registered: ${command}`);
        }

        this.handlers.set(command, handler);
    }

    async execute(command, payload) {
        const handler = this.handlers.get(command);

        if (!handler) {
            throw new Error(`Command handler not found: ${command}`);
        }

        return handler(payload);
    }
}

module.exports = CommandBus;
