#!/usr/bin/env node
"use strict";

const orchestrator =
    require("../runtime/orchestrator");

process.on(
    "SIGINT",
    () => {
        orchestrator.stop();
    }
);

process.on(
    "SIGTERM",
    () => {
        orchestrator.stop();
    }
);

orchestrator
    .run()
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
