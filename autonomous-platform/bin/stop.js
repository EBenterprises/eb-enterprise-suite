#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const config = require("../core/config");

const target =
    path.join(
        config.paths.state,
        "stop.request"
    );

fs.writeFileSync(
    target,
    new Date().toISOString()
);

console.log(
    "STOP REQUEST RECORDED"
);
