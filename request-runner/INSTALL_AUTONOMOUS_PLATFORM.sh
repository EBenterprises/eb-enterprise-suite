#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/autonomous-platform"

mkdir -p "$ROOT"/{bin,core,engine,runtime,state,plans,logs,adapters,plugins,worktrees,artifacts,checkpoints,policies}

cat > "$ROOT/core/config.js" <<'JS'
"use strict";

const path = require("path");

const ROOT = path.resolve(__dirname, "..");

module.exports = {
    ROOT,

    paths: {
        state: path.join(ROOT, "state"),
        plans: path.join(ROOT, "plans"),
        logs: path.join(ROOT, "logs"),
        adapters: path.join(ROOT, "adapters"),
        plugins: path.join(ROOT, "plugins"),
        worktrees: path.join(ROOT, "worktrees"),
        artifacts: path.join(ROOT, "artifacts"),
        checkpoints: path.join(ROOT, "checkpoints"),
        policies: path.join(ROOT, "policies")
    },

    autonomous: true,
    continuous: true,
    persistent: true,
    selfRepair: true,
    selfVerify: true,
    autoPlan: true,
    autoReplan: true,
    autoBranch: true,
    autoCheckpoint: true,
    autoResume: true,

    neverRequireContinue: true,

    completion: {
        requireBuild: true,
        requireTests: true,
        requireVerification: true,
        requireDeployment: true,
        requireHealthCheck: true
    }
};
JS

cat > "$ROOT/core/store.js" <<'JS'
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
JS

cat > "$ROOT/core/project.js" <<'JS'
"use strict";

const crypto = require("crypto");
const store = require("./store");

function create(request) {
    const project = {
        id: crypto.randomUUID(),
        request,
        state: "received",

        createdAt:
            new Date().toISOString(),

        updatedAt:
            new Date().toISOString(),

        requirements: [],
        tasks: [],
        blockers: [],
        history: [],

        counters: {
            plans: 0,
            builds: 0,
            tests: 0,
            repairs: 0,
            deployments: 0,
            verifications: 0
        }
    };

    store.write(
        "project",
        project
    );

    return project;
}

function get() {
    return store.read(
        "project",
        null
    );
}

function update(patch) {
    const current = get();

    if (!current) {
        throw new Error(
            "No active project"
        );
    }

    const next = {
        ...current,
        ...patch,
        updatedAt:
            new Date().toISOString()
    };

    store.write(
        "project",
        next
    );

    return next;
}

function event(type, data = {}) {
    const current = get();

    if (!current) {
        throw new Error(
            "No active project"
        );
    }

    current.history.push({
        id: crypto.randomUUID(),
        type,
        data,
        timestamp:
            new Date().toISOString()
    });

    current.updatedAt =
        new Date().toISOString();

    store.write(
        "project",
        current
    );
}

module.exports = {
    create,
    get,
    update,
    event
};
JS

cat > "$ROOT/bin/status.js" <<'JS'
#!/usr/bin/env node

const project =
    require("../core/project");

const p = project.get();

if (!p) {
    console.log(
        "NO ACTIVE PROJECT"
    );
    process.exit(0);
}

console.log(
    JSON.stringify(
        {
            id: p.id,
            state: p.state,
            request: p.request,
            counters: p.counters,
            blockers: p.blockers,
            updatedAt: p.updatedAt
        },
        null,
        2
    )
);
JS

cat > "$ROOT/bin/platform.js" <<'JS'
#!/usr/bin/env node

const project =
    require("../core/project");

const request =
    process.argv
        .slice(2)
        .join(" ")
        .trim();

if (!request) {
    console.error(
        "REQUEST REQUIRED"
    );

    process.exit(1);
}

if (project.get()) {
    console.error(
        "ACTIVE PROJECT EXISTS"
    );

    console.error(
        "Use: node bin/status.js"
    );

    process.exit(1);
}

project.create(request);

console.log(
    "AUTONOMOUS PROJECT CREATED"
);

console.log(
    "The persistent execution engine will take over."
);
JS

chmod +x "$ROOT"/bin/*.js

echo
echo "=============================================================="
echo " AUTONOMOUS PLATFORM COMPLETION ENGINE®"
echo " BOOTSTRAP INSTALLED"
echo "=============================================================="
echo
echo "ROOT:"
echo "$ROOT"
echo
echo "✓ Persistent state"
echo "✓ Project registry"
echo "✓ Autonomous configuration"
echo "✓ Status interface"
echo "✓ One-request project interface"
echo
echo "NEXT INSTALLER:"
echo "INSTALL_AUTONOMOUS_ENGINE_02.sh"
echo
echo "=============================================================="
