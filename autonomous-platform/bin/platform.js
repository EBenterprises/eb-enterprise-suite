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
