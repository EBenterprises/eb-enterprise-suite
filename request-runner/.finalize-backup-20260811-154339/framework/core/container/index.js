class Container {
    constructor() {
        this.services = new Map();
        this.factories = new Map();
        this.singletons = new Map();
    }

    register(name, value) {
        this.services.set(name, value);
        return this;
    }

    factory(name, factory) {
        this.factories.set(name, factory);
        return this;
    }

    singleton(name, factory) {
        this.factories.set(name, factory);
        this.singletons.set(name, undefined);
        return this;
    }

    resolve(name) {
        if (this.services.has(name)) {
            return this.services.get(name);
        }

        if (!this.factories.has(name)) {
            throw new Error(`Service not registered: ${name}`);
        }

        if (this.singletons.has(name)) {
            let instance = this.singletons.get(name);

            if (instance === undefined) {
                instance = this.factories.get(name)(this);
                this.singletons.set(name, instance);
            }

            return instance;
        }

        return this.factories.get(name)(this);
    }

    has(name) {
        return (
            this.services.has(name) ||
            this.factories.has(name)
        );
    }
}

module.exports = Container;
