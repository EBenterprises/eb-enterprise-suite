const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT = path.resolve(__dirname, "../..");
const DATA_DIR = path.join(ROOT, "data");

fs.mkdirSync(DATA_DIR, { recursive: true });

function id(prefix = "id") {
    return `${prefix}_${Date.now()}_${crypto.randomBytes(6).toString("hex")}`;
}

function fileFor(collection) {
    return path.join(DATA_DIR, `${collection}.json`);
}

function read(collection) {
    const file = fileFor(collection);

    if (!fs.existsSync(file)) {
        return [];
    }

    try {
        const raw = fs.readFileSync(file, "utf8");

        if (!raw.trim()) {
            return [];
        }

        const value = JSON.parse(raw);

        return Array.isArray(value) ? value : [];
    } catch (error) {
        throw new Error(
            `Unable to read persistent collection "${collection}": ${error.message}`
        );
    }
}

function write(collection, records) {
    const file = fileFor(collection);
    const tmp = `${file}.tmp`;

    fs.writeFileSync(
        tmp,
        JSON.stringify(records, null, 2),
        "utf8"
    );

    fs.renameSync(tmp, file);

    return records;
}

function now() {
    return new Date().toISOString();
}

class PersistentRepository {
    constructor(collection) {
        if (!collection) {
            throw new TypeError("PersistentRepository requires a collection");
        }

        this.collection = collection;
    }

    all() {
        return read(this.collection);
    }

    findById(recordId) {
        return this.all().find(item => item.id === recordId) || null;
    }

    findBy(field, value) {
        return this.all().filter(item => item[field] === value);
    }

    create(input = {}) {
        const timestamp = now();

        const record = {
            id: input.id || id(this.collection),
            ...input,
            createdAt: input.createdAt || timestamp,
            updatedAt: timestamp
        };

        const records = this.all();
        records.push(record);
        write(this.collection, records);

        return record;
    }

    update(recordId, patch = {}) {
        const records = this.all();
        const index = records.findIndex(item => item.id === recordId);

        if (index === -1) {
            return null;
        }

        records[index] = {
            ...records[index],
            ...patch,
            id: records[index].id,
            updatedAt: now()
        };

        write(this.collection, records);

        return records[index];
    }

    delete(recordId) {
        const records = this.all();
        const index = records.findIndex(item => item.id === recordId);

        if (index === -1) {
            return null;
        }

        const removed = records.splice(index, 1)[0];

        write(this.collection, records);

        return removed;
    }

    count() {
        return this.all().length;
    }

    clear() {
        write(this.collection, []);
    }
}

module.exports = {
    PersistentRepository,
    DATA_DIR,
    id,
    now
};
