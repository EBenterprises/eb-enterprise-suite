"use strict";

const fs = require("fs");
const path = require("path");
const config = require("./config");

const file = path.join(
    config.paths.logs,
    "platform.log"
);

function write(level, message, data) {
    fs.mkdirSync(path.dirname(file), { recursive: true });

    const record = {
        timestamp: new Date().toISOString(),
        level,
        message,
        data: data || null
    };

    fs.appendFileSync(
        file,
        JSON.stringify(record) + "\n"
    );

    console.log(
        `[${record.timestamp}] [${level}] ${message}`
    );
}

module.exports = {
    info: (m, d) => write("INFO", m, d),
    warn: (m, d) => write("WARN", m, d),
    error: (m, d) => write("ERROR", m, d)
};
