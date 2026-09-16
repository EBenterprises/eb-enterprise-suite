import { NextResponse } from "next/server";
import {
  customerBalance,
  getCustomer,
} from "@/lib/services/customers";

export const dynamic = "force-dynamic";

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const customer = getCustomer(id);

    if (!customer) {
      return NextResponse.json(
        { ok: false, error: "Customer not found." },
        { status: 404 }
      );
    }

    return NextResponse.json({
      ok: true,
      customer,
      balance: customerBalance(id),
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Unable to load customer.",
      },
      { status: 500 }
    );
  }
}
