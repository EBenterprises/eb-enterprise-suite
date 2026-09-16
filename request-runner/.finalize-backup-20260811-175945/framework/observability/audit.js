"use strict";

const fs = require("fs");
const path = require("path");

const file = path.join(
    process.cwd(),
    "data",
    "audit.json"
);

function read() {
    if (!fs.existsSync(file)) return [];
    const value = JSON.parse(fs.readFileSync(file, "utf8"));
    return Array.isArray(value) ? value : [];
}

function record(event, payload = {}) {
    const entries = read();

    entries.push({
        id: `audit_${Date.now()}_${Math.random().toString(36).slice(2,8)}`,
        event,
        payload,
        timestamp: new Date().toISOString()
    });

    fs.writeFileSync(
        file,
        JSON.stringify(entries, null, 2)
    );

    return entries.at(-1);
}

module.exports = {
    read,
    record
};
