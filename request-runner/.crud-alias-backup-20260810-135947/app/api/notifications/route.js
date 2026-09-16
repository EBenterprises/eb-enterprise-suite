const {
    createCrudHandlers
} = require("../../../framework/api/crud-route");

const handlers = createCrudHandlers("notifications");

export const GET = handlers.GET;
export const POST = handlers.POST;
