const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "../..");

function loadConfig() {
    const file = path.join(root, "config", "platform.json");

    if (!fs.existsSync(file)) {
        return {};
    }

    return JSON.parse(fs.readFileSync(file, "utf8"));
}

module.exports = {
    loadConfig
};
