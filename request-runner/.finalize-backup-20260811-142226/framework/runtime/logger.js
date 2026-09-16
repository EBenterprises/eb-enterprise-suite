function timestamp() {
    return new Date().toISOString();
}

function write(level, message, metadata = {}) {
    const record = {
        timestamp: timestamp(),
        level,
        message,
        ...metadata
    };

    console.log(JSON.stringify(record));
}

module.exports = {
    info: (message, metadata) => write("info", message, metadata),
    warn: (message, metadata) => write("warn", message, metadata),
    error: (message, metadata) => write("error", message, metadata),
    debug: (message, metadata) => write("debug", message, metadata)
};
