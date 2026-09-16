import { NextRequest, NextResponse } from "next/server";
import {
  createCharge,
  listTransactions,
  transactionStats,
} from "@/lib/services/transactions";

export const dynamic = "force-dynamic";

function centsFromAmount(value: unknown): number {
  const amount = Number(value);

  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error("Amount must be greater than zero.");
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
      transactions: listTransactions(customerId),
      stats: transactionStats(customerId),
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Unable to load transactions.",
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const transaction = createCharge({
      customer_id: String(body.customer_id ?? ""),
      occurred_at: body.occurred_at || undefined,
      location: body.location ?? null,
      item: body.item ?? null,
      quantity:
        body.quantity === "" ||
        body.quantity === null ||
        body.quantity === undefined
          ? null
          : Number(body.quantity),
      amount_cents: centsFromAmount(body.amount),
      note: body.note ?? null,
    });

    return NextResponse.json(
      {
        ok: true,
        transaction,
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
            : "Unable to create transaction.",
      },
      { status: 400 }
    );
  }
}
