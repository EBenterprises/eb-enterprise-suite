export async function GET() {
  return Response.json({
    ok: true,
    application: "Errands®",
    version: "1.0.0",
    status: "operational"
  });
}
