"use strict";

const service = require("../application-service");

function json(data, status = 200) {
    return Response.json(data, {
        status,
        headers: {
            "Cache-Control": "no-store"
        }
    });
}

async function readBody(request) {
    try {
        return await request.json();
    } catch {
        return {};
    }
}

function resolveId(params) {
    if (!params) return null;

    if (typeof params.then === "function") {
        return params.then(value => value?.id ?? null);
    }

    return params.id ?? null;
}

async function getId(context) {
    const result = resolveId(context?.params);

    if (result && typeof result.then === "function") {
        return await result;
    }

    return result;
}

function list(collection) {
    const repository = service.repository(collection);

    if (typeof repository.findAll === "function") {
        return repository.findAll();
    }

    if (typeof service.list === "function") {
        return service.list(collection);
    }

    return [];
}

function create(collection, data) {
    return service.create(collection, data);
}

function get(collection, id) {
    return service.get(collection, id);
}

function update(collection, id, data) {
    return service.update(collection, id, data);
}

function remove(collection, id) {
    return service.remove(collection, id);
}

function createCrudRoute(collection) {
    if (!collection || typeof collection !== "string") {
        throw new TypeError("CRUD collection must be a string");
    }

    const GET = async (request, context = {}) => {
        const id = await getId(context);

        if (id !== null && id !== undefined && id !== "") {
            const record = await get(collection, id);

            if (!record) {
                return json({
                    ok: false,
                    error: "Not found",
                    collection,
                    id
                }, 404);
            }

            return json({
                ok: true,
                data: record,
                record,
                collection
            });
        }

        const records = await list(collection);

        return json({
            ok: true,
            data: records,
            records,
            collection,
            count: Array.isArray(records) ? records.length : 0
        });
    };

    const POST = async request => {
        const body = await readBody(request);

        const record = await create(collection, body);

        return json({
            ok: true,
            data: record,
            record,
            collection
        }, 201);
    };

    const PATCH = async request => {
        const id = await getId(arguments[1]);

        if (!id) {
            return json({
                ok: false,
                error: "Missing id",
                collection
            }, 400);
        }

        const body = await readBody(request);
        const record = await update(collection, id, body);

        if (!record) {
            return json({
                ok: false,
                error: "Not found",
                collection,
                id
            }, 404);
        }

        return json({
            ok: true,
            data: record,
            record,
            collection
        });
    };

    const DELETE = async (request, context = {}) => {
        const id = await getId(context);

        if (!id) {
            return json({
                ok: false,
                error: "Missing id",
                collection
            }, 400);
        }

        const removed = await remove(collection, id);

        if (!removed) {
            return json({
                ok: false,
                error: "Not found",
                collection,
                id
            }, 404);
        }

        return json({
            ok: true,
            data: removed,
            record: removed,
            collection,
            id
        });
    };

    return {
        GET,
        POST,
        PATCH,
        DELETE
    };
}

const crudRoute = createCrudRoute;

module.exports = createCrudRoute;
module.exports.createCrudRoute = createCrudRoute;
module.exports.crudRoute = crudRoute;
module.exports.createCollectionHandlers = createCrudRoute;
module.exports.json = json;
module.exports.readBody = readBody;
