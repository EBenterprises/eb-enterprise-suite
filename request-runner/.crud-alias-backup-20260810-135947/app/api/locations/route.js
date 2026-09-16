const {
    createCrudHandlers
} = require("../../../framework/api/crud-route");

const handlers = createCrudHandlers("locations");

export const GET = handlers.GET;
export const POST = handlers.POST;
