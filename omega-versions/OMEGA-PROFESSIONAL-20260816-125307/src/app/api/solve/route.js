import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const SYSTEM_PROMPT = `
You are the GPT intelligence layer inside OMEGA®.

OMEGA® is a professional generative intelligence system.

For every user request:

1. Understand the actual objective.
2. Identify requirements and constraints.
3. Form an architecture or solution.
4. Generate useful implementation ideas.
5. Evaluate tradeoffs and risks.
6. Produce concrete next actions.
7. Never claim something was completed if it was not.
8. Prefer practical, technically rigorous answers.
9. Treat the request as an active workspace task, not a generic chatbot conversation.

Your response is being rendered live inside the OMEGA® private workspace.
Write progressively useful content as you work.
`;

export async function POST(request) {
  try {
    const body = await request.json();
    const task = String(body?.request || "").trim();

    if (!task) {
      return NextResponse.json(
        {
          status: "ERROR",
          message: "A task is required."
        },
        { status: 400 }
      );
    }

    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      return NextResponse.json(
        {
          status: "CONFIGURATION_REQUIRED",
          title: "GPT connection required",
          message: "OPENAI_API_KEY is not configured."
        },
        { status: 503 }
      );
    }

    const model =
      process.env.OMEGA_GPT_MODEL ||
      process.env.OPENAI_MODEL ||
      "gpt-5.6";

    const upstream = await fetch(
      "https://api.openai.com/v1/responses",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
          Accept: "text/event-stream"
        },
        body: JSON.stringify({
          model,
          instructions: SYSTEM_PROMPT,
          input: task,
          stream: true
        }),
        cache: "no-store"
      }
    );

    if (!upstream.ok) {
      const errorText = await upstream.text();

      return NextResponse.json(
        {
          status: "GPT_ERROR",
          title: "GPT request failed",
          message: errorText || `OpenAI HTTP ${upstream.status}`
        },
        { status: upstream.status }
      );
    }

    if (!upstream.body) {
      return NextResponse.json(
        {
          status: "GPT_ERROR",
          message: "OpenAI returned no streaming body."
        },
        { status: 502 }
      );
    }

    return new Response(upstream.body, {
      status: 200,
      headers: {
        "Content-Type": "text/event-stream; charset=utf-8",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
        "X-Accel-Buffering": "no"
      }
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "ERROR",
        title: "OMEGA® execution error",
        message:
          error instanceof Error
            ? error.message
            : String(error)
      },
      { status: 500 }
    );
  }
}
