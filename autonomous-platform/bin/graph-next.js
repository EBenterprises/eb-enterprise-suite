#!/usr/bin/env node

const graph =
    require("../engine/work-graph");

console.log(
    JSON.stringify(
        graph.next(),
        null,
        2
    )
);
