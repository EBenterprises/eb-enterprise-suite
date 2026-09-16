import { NextResponse } from "next/server";
import { OMEGA } from "../../../omega.js";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const omega = await OMEGA.boot(process.cwd());

    return NextResponse.json({
      status: "ONLINE",
      ...omega.status(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "OFFLINE",
        error: error instanceof Error ? error.message : "OMEGA® unavailable",
      },
      { status: 500 }
    );
  }
}
