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
