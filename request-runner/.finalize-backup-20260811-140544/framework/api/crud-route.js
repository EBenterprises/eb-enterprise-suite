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

async function getId(context) {
    const params = context?.params;

    if (!params) {
        return null;
    }

    if (typeof params.then === "function") {
        const resolved = await params;
        return resolved?.id ?? null;
    }

    return params.id ?? null;
}

async function list(collection) {
    const repository = service.repository(collection);

    if (typeof repository.findAll === "function") {
        return await repository.findAll();
    }

    if (typeof service.list === "function") {
        return await service.list(collection);
    }

    return [];
}

async function create(collection, data) {
    return await service.create(collection, data);
}

async function get(collection, id) {
    return await service.get(collection, id);
}

async function update(collection, id, data) {
    return await service.update(collection, id, data);
}

async function remove(collection, id) {
    return await service.remove(collection, id);
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

    const POST = async (request, context = {}) => {
        const body = await readBody(request);

        const record = await create(collection, body);

        return json({
            ok: true,
            data: record,
            record,
            collection
        }, 201);
    };

    const PATCH = async (request, context = {}) => {
        const id = await getId(context);

        if (!id) {
            return json({
                ok: false,
                error: "Missing id",
                collection
            }, 400);
        }

        const body = await readBody(request);

        const record = await update(
            collection,
            id,
            body
        );

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
            collection,
            id
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

        const removed = await remove(
            collection,
            id
        );

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


/*
 * EB PLATFORM® CRUD compatibility contract.
 *
 * Route modules use:
 *   createCrudHandlers(collection)
 *   createIdHandlers(collection)
 *
 * Preserve the existing CRUD implementation and expose
 * explicit collection/id handler factories.
 */

function createCrudHandlers(collection) {
    const handlers = createCrudRoute(collection);

    return {
        GET: handlers.GET,
        POST: handlers.POST
    };
}

function createIdHandlers(collection) {
    const handlers = createCrudRoute(collection);

    return {
        GET: handlers.GET,
        PATCH: handlers.PATCH,
        DELETE: handlers.DELETE
    };
}

module.exports.createCrudHandlers = createCrudHandlers;
module.exports.createIdHandlers = createIdHandlers;
