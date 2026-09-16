export async function GET() {
  return Response.json({
    data: [],
    count: 0,
    service: "errands"
  });
}

export async function POST(request) {
  const body = await request.json().catch(() => null);

  if (!body || typeof body !== "object") {
    return Response.json(
      {
        error: "INVALID_REQUEST"
      },
      {
        status: 400
      }
    );
  }

  const errand = {
    id: crypto.randomUUID(),
    status: "requested",
    createdAt: new Date().toISOString(),
    ...body
  };

  return Response.json(
    {
      data: errand
    },
    {
      status: 201
    }
  );
}
