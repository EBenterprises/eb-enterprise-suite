class Audit {
    constructor(repository = null) {
        this.repository = repository;
    }

    async record(event) {
        const record = {
            id: Date.now().toString(36),
            timestamp: new Date().toISOString(),
            ...event
        };

        if (this.repository) {
            await this.repository.create(record);
        }

        return record;
    }
}

module.exports = Audit;
