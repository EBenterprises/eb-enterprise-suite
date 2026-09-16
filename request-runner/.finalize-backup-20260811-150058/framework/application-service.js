const EventBus = require("./core/events/event-bus");
const {
    PersistentRepository
} = require("./data/persistence");

const eventBus = new EventBus();

const repositories = new Map();

function repository(collection) {
    if (!repositories.has(collection)) {
        repositories.set(
            collection,
            new PersistentRepository(collection)
        );
    }

    return repositories.get(collection);
}

function validateEntity(input) {
    if (!input || typeof input !== "object" || Array.isArray(input)) {
        throw new TypeError("Request body must be a JSON object");
    }

    return input;
}

function list(collection, filters = {}) {
    let records = repository(collection).all();

    for (const [key, value] of Object.entries(filters)) {
        if (
            value !== undefined &&
            value !== null &&
            value !== ""
        ) {
            records = records.filter(
                record => String(record[key]) === String(value)
            );
        }
    }

    return records;
}

function get(collection, id) {
    return repository(collection).findById(id);
}

function create(collection, input) {
    const data = validateEntity(input);

    const record = repository(collection).create(data);

    eventBus.publish(`${collection}.created`, record);
    eventBus.publish("entity.created", {
        collection,
        record
    });

    return record;
}

function update(collection, id, input) {
    const data = validateEntity(input);

    const record = repository(collection).update(id, data);

    if (!record) {
        return null;
    }

    eventBus.publish(`${collection}.updated`, record);
    eventBus.publish("entity.updated", {
        collection,
        record
    });

    return record;
}

function remove(collection, id) {
    const record = repository(collection).delete(id);

    if (!record) {
        return null;
    }

    eventBus.publish(`${collection}.deleted`, record);
    eventBus.publish("entity.deleted", {
        collection,
        record
    });

    return record;
}

function summary() {
    const collections = [
        "customers",
        "requests",
        "orders",
        "drivers",
        "locations",
        "scheduling",
        "payments",
        "notifications",
        "operations",
        "administration"
    ];

    const counts = {};

    for (const collection of collections) {
        counts[collection] = repository(collection).count();
    }

    return {
        timestamp: new Date().toISOString(),
        collections: counts
    };
}

module.exports = {
    eventBus,
    repository,
    list,
    get,
    create,
    update,
    remove,
    summary
};
