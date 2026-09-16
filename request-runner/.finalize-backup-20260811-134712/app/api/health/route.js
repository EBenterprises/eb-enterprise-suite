const service = require("../../../framework/application-service");

export const dynamic = "force-dynamic";

export async function GET() {
    const summary = service.summary();

    return Response.json({
        ok: true,
        platform: "EB Platform®",
        status: "healthy",
        timestamp: new Date().toISOString(),
        persistence: "json",
        data: summary.collections
    });
}
