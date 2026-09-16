class ModuleRegistry {
    constructor() {
        this.modules = new Map();
    }

    register(module) {
        if (!module || !module.name) {
            throw new Error("Invalid module");
        }

        if (this.modules.has(module.name)) {
            throw new Error(`Module already registered: ${module.name}`);
        }

        this.modules.set(module.name, module);
        return module;
    }

    get(name) {
        return this.modules.get(name);
    }

    list() {
        return [...this.modules.values()];
    }

    async initialize(context) {
        for (const module of this.modules.values()) {
            if (typeof module.initialize === "function") {
                await module.initialize(context);
            }
        }
    }

    async shutdown(context) {
        const modules = [...this.modules.values()].reverse();

        for (const module of modules) {
            if (typeof module.shutdown === "function") {
                await module.shutdown(context);
            }
        }
    }
}

module.exports = ModuleRegistry;
