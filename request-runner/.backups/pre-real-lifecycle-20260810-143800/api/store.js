const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const DATA_DIR = path.join(ROOT, "data");

fs.mkdirSync(DATA_DIR, { recursive: true });

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
            `Unable to read collection ${collection}: ${error.message}`
        );
    }
}

function write(collection, records) {
    const file = fileFor(collection);
    const temp = `${file}.${process.pid}.tmp`;

    fs.writeFileSync(
        temp,
        JSON.stringify(records, null, 2) + "\n",
        "utf8"
    );

    fs.renameSync(temp, file);

    return records;
}

function all(collection) {
    return read(collection);
}

function findById(collection, id) {
    return read(collection).find(item => String(item.id) === String(id)) || null;
}

function insert(collection, record) {
    const records = read(collection);

    records.push(record);

    write(collection, records);

    return record;
}

function update(collection, id, patch) {
    const records = read(collection);

    const index = records.findIndex(
        item => String(item.id) === String(id)
    );

    if (index === -1) {
        return null;
    }

    records[index] = {
        ...records[index],
        ...patch,
        updatedAt: new Date().toISOString()
    };

    write(collection, records);

    return records[index];
}

function remove(collection, id) {
    const records = read(collection);

    const next = records.filter(
        item => String(item.id) !== String(id)
    );

    if (next.length === records.length) {
        return false;
    }

    write(collection, next);

    return true;
}

function count(collection) {
    return read(collection).length;
}

module.exports = {
    DATA_DIR,
    all,
    findById,
    insert,
    update,
    remove,
    count
};
