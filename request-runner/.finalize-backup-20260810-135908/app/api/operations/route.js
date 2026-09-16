const {
    createCrudHandlers
} = require("../../../framework/api/crud-route");

const handlers = createCrudHandlers("operations");

export const GET = handlers.GET;
export const POST = handlers.POST;
