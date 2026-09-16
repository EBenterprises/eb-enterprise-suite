const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");

const checks = [];

function check(name, test) {
    try {
        test();
        checks.push({ name, status: "ok" });
    } catch (error) {
        checks.push({
            name,
            status: "error",
            error: error.message
        });
    }
}

check("package.json", () =>
    fs.accessSync(path.join(root, "package.json"))
);

check("framework", () =>
    fs.accessSync(path.join(root, "framework", "index.js"))
);

check("kernel", () =>
    fs.accessSync(path.join(root, "framework", "core", "application.js"))
);

check("data layer", () =>
    fs.accessSync(path.join(root, "framework", "data", "repository.js"))
);

check("realtime layer", () =>
    fs.accessSync(path.join(root, "framework", "realtime", "realtime-bus.js"))
);

check("security layer", () =>
    fs.accessSync(path.join(root, "framework", "security", "audit.js"))
);

check("configuration", () =>
    fs.accessSync(path.join(root, "config", "platform.json"))
);

check("Request Runner modules", () =>
    fs.accessSync(path.join(root, "apps", "request-runner", "index.js"))
);

const failed = checks.some(item => item.status !== "ok");

console.log(JSON.stringify({
    platform: "EB Platform®",
    status: failed ? "failed" : "healthy",
    checks
}, null, 2));

process.exit(failed ? 1 : 0);
