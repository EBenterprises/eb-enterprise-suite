class Entity {
    constructor(data = {}) {
        Object.assign(this, data);

        if (!this.id) {
            this.id = Entity.id();
        }

        if (!this.createdAt) {
            this.createdAt = new Date().toISOString();
        }

        this.updatedAt = new Date().toISOString();
    }

    touch() {
        this.updatedAt = new Date().toISOString();
        return this;
    }

    static id() {
        return (
            Date.now().toString(36) +
            "-" +
            Math.random().toString(36).slice(2, 10)
        );
    }
}

module.exports = Entity;
