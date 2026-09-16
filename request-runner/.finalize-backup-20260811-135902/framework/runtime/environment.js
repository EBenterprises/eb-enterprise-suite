const os = require("os");

function detectEnvironment() {
    const platform = process.platform;
    const architecture = process.arch;

    return {
        platform,
        architecture,
        android: platform === "android",
        linux: platform === "linux",
        darwin: platform === "darwin",
        windows: platform === "win32",
        arm64: architecture === "arm64",
        node: process.version,
        hostname: os.hostname(),
        cpuCount: os.cpus().length
    };
}

module.exports = {
    detectEnvironment
};
