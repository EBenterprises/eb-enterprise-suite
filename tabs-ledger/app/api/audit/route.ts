import { NextResponse } from "next/server";
import { verifyAuditChain } from "@/lib/services/audit";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const result = verifyAuditChain();

    return NextResponse.json(result, {
      status: result.ok ? 200 : 409,
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Audit verification failed.",
      },
      { status: 500 }
    );
  }
}
