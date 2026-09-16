const service = require("../application-service");

function json(data, status = 200) {
    return Response.json(data, {
        status,
        headers: {
            "Cache-Control": "no-store"
        }
    });
}

async function body(request) {
    try {
        return await request.json();
    } catch {
        return {};
    }
}

function createCrudHandlers(collection) {
    return {
        async GET(request) {
            const { searchParams } = new URL(request.url);

            const filters = Object.fromEntries(
                searchParams.entries()
            );

            return json({
                ok: true,
                collection,
                data: service.list(collection, filters)
            });
        },

        async POST(request) {
            try {
                const input = await body(request);
                const record = service.create(collection, input);

                return json(
                    {
                        ok: true,
                        collection,
                        data: record
                    },
                    201
                );
            } catch (error) {
                return json(
                    {
                        ok: false,
                        error: error.message
                    },
                    400
                );
            }
        }
    };
}

function createIdHandlers(collection) {
    return {
        async GET(_request, context) {
            const { id } = await context.params;
            const record = service.get(collection, id);

            if (!record) {
                return json(
                    {
                        ok: false,
                        error: "Not found"
                    },
                    404
                );
            }

            return json({
                ok: true,
                collection,
                data: record
            });
        },

        async PATCH(request, context) {
            try {
                const { id } = await context.params;
                const input = await body(request);

                const record = service.update(
                    collection,
                    id,
                    input
                );

                if (!record) {
                    return json(
                        {
                            ok: false,
                            error: "Not found"
                        },
                        404
                    );
                }

                return json({
                    ok: true,
                    collection,
                    data: record
                });
            } catch (error) {
                return json(
                    {
                        ok: false,
                        error: error.message
                    },
                    400
                );
            }
        },

        async DELETE(_request, context) {
            const { id } = await context.params;

            const record = service.remove(collection, id);

            if (!record) {
                return json(
                    {
                        ok: false,
                        error: "Not found"
                    },
                    404
                );
            }

            return json({
                ok: true,
                collection,
                data: record
            });
        }
    };
}

module.exports = {
    createCrudHandlers,
    createIdHandlers
};
