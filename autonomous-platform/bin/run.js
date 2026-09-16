#!/usr/bin/env node

const path = require("path");

const engine =
    path.join(
        __dirname,
        "..",
        "engine",
        "executor.js"
    );

require(engine);
