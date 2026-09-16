import { NextRequest, NextResponse } from "next/server";
import {
  customerPaymentSummary,
  listPayments,
  recordPayment,
} from "@/lib/services/payments";

export const dynamic = "force-dynamic";

function centsFromAmount(value: unknown): number {
  const amount = Number(value);

  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error("Payment amount must be greater than zero.");
  }

  const cents = Math.round(amount * 100);

  if (!Number.isSafeInteger(cents) || cents <= 0) {
    throw new Error("Invalid monetary amount.");
  }

  return cents;
}

export async function GET(request: NextRequest) {
  try {
    const customerId =
      request.nextUrl.searchParams.get("customer_id") || undefined;

    return NextResponse.json({
      ok: true,
      payments: listPayments(customerId),
      ...(customerId
        ? { summary: customerPaymentSummary(customerId) }
        : {}),
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Unable to load payments.",
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const result = recordPayment({
      customer_id: String(body.customer_id ?? ""),
      amount_cents: centsFromAmount(body.amount),
      occurred_at: body.occurred_at || undefined,
      location: body.location ?? null,
      note: body.note ?? null,
    });

    return NextResponse.json(
      {
        ok: true,
        ...result,
      },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Unable to record payment.",
      },
      { status: 400 }
    );
  }
}
