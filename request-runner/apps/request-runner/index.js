const modules = [
    require("./customers"),
    require("./requests"),
    require("./orders"),
    require("./dispatch"),
    require("./drivers"),
    require("./locations"),
    require("./scheduling"),
    require("./payments"),
    require("./notifications"),
    require("./operations"),
    require("./administration")
];

module.exports = modules;

module.exports.runners = require("./runners");

module.exports.dispatchRunner = require("./dispatch-runner");

module.exports.dispatchState = require("./dispatch-state");

module.exports.requestQueue = require("./request-queue");

module.exports.dispatch = require("./dispatch");
