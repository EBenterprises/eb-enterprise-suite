class PlatformError extends Error {
    constructor(message, options = {}) {
        super(message);

        this.name = options.name || "PlatformError";
        this.code = options.code || "PLATFORM_ERROR";
        this.status = options.status || 500;
        this.details = options.details || {};
    }
}

module.exports = PlatformError;
