class QueryBus {
    constructor() {
        this.handlers = new Map();
    }

    register(query, handler) {
        if (this.handlers.has(query)) {
            throw new Error(`Query already registered: ${query}`);
        }

        this.handlers.set(query, handler);
    }

    async execute(query, payload) {
        const handler = this.handlers.get(query);

        if (!handler) {
            throw new Error(`Query handler not found: ${query}`);
        }

        return handler(payload);
    }
}

module.exports = QueryBus;
