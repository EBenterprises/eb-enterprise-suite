const {
    createCrudHandlers
} = require("../../../../framework/api/crud-route");

const handlers = createCrudHandlers("administration");

export const GET = handlers.GET;
export const POST = handlers.POST;
