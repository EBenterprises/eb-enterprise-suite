const fs = require("fs");
const path = require("path");
const Repository = require("../repository");

class JsonRepository extends Repository {
    constructor(file) {
        super();
        this.file = path.resolve(file);
        this.ensure();
    }

    ensure() {
        fs.mkdirSync(path.dirname(this.file), { recursive: true });

        if (!fs.existsSync(this.file)) {
            fs.writeFileSync(this.file, "[]\n");
        }
    }

    read() {
        this.ensure();
        return JSON.parse(fs.readFileSync(this.file, "utf8"));
    }

    write(records) {
        const temp = `${this.file}.tmp`;

        fs.writeFileSync(
            temp,
            JSON.stringify(records, null, 2) + "\n"
        );

        fs.renameSync(temp, this.file);
    }

    async findAll() {
        return this.read();
    }

    async findById(id) {
        return this.read().find(item => item.id === id) || null;
    }

    async create(record) {
        const records = this.read();
        records.push(record);
        this.write(records);
        return record;
    }

    async update(id, changes) {
        const records = this.read();
        const index = records.findIndex(item => item.id === id);

        if (index === -1) {
            return null;
        }

        records[index] = {
            ...records[index],
            ...changes
        };

        this.write(records);

        return records[index];
    }

    async delete(id) {
        const records = this.read();
        const filtered = records.filter(item => item.id !== id);

        this.write(filtered);

        return filtered.length !== records.length;
    }
}

module.exports = JsonRepository;
