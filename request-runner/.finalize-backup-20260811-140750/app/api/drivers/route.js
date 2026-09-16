const {
    createCrudHandlers
} = require("@framework/api/crud-route");

const handlers = createCrudHandlers("drivers");

export const GET = handlers.GET;
export const POST = handlers.POST;
