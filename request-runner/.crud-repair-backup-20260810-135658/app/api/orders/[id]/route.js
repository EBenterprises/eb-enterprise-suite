const {
    createIdHandlers
} = require("../../../../../framework/api/crud-route");

const handlers = createIdHandlers("orders");

export const GET = handlers.GET;
export const PATCH = handlers.PATCH;
export const DELETE = handlers.DELETE;
