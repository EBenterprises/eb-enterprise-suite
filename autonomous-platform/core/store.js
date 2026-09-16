"use strict";

const fs = require("fs");
const path = require("path");
const config = require("./config");

function file(name) {
    fs.mkdirSync(config.paths.state, {
        recursive: true
    });

    return path.join(
        config.paths.state,
        name + ".json"
    );
}

function read(name, fallback) {
    const f = file(name);

    if (!fs.existsSync(f)) {
        return fallback;
    }

    try {
        return JSON.parse(
            fs.readFileSync(f, "utf8")
        );
    } catch (_) {
        return fallback;
    }
}

function write(name, value) {
    const f = file(name);
    const tmp = f + ".tmp";

    fs.writeFileSync(
        tmp,
        JSON.stringify(value, null, 2)
    );

    fs.renameSync(tmp, f);

    return value;
}

module.exports = {
    read,
    write
};
