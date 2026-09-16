import { NextResponse } from "next/server";
import { reconcileLedger } from "@/lib/services/reconciliation";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const result = reconcileLedger();

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
            : "Reconciliation failed.",
      },
      { status: 500 }
    );
  }
}
