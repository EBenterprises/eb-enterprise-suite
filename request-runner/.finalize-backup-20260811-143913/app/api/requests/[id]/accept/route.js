const domain = require("../../../../../api/domain-service");
const store = require("../../../../../api/store");

async function POST(request, context) {
    const params = await context.params;
    const id = params.id;

    const existing = store.findById("requests", id);

    if (!existing) {
        return Response.json(
            {
                ok: false,
                error: "Request not found",
                collection: "requests",
                id
            },
            { status: 404 }
        );
    }

    try {
        const order = domain.createOrderFromRequest(existing);

        const updated = store.findById("requests", id);

        return Response.json(
            {
                request: updated,
                order
            },
            { status: 201 }
        );
    } catch (error) {
        console.error("[REQUEST ACCEPT]", error);

        return Response.json(
            {
                ok: false,
                error: error.message || "Unable to accept request"
            },
            { status: 400 }
        );
    }
}

module.exports = { POST };
