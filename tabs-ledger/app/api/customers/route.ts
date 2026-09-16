import { NextRequest, NextResponse } from "next/server";
import {
  createCustomer,
  listCustomers,
} from "@/lib/services/customers";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    return NextResponse.json({
      ok: true,
      customers: listCustomers(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error: error instanceof Error ? error.message : "Unable to list customers.",
      },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const customer = createCustomer({
      name: String(body.name ?? ""),
      email: body.email ?? null,
      phone: body.phone ?? null,
      notes: body.notes ?? null,
      metadata: body.metadata ?? {},
    });

    return NextResponse.json(
      {
        ok: true,
        customer,
      },
      { status: 201 }
    );
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unable to create customer.";

    return NextResponse.json(
      {
        ok: false,
        error: message,
      },
      { status: message.includes("already exists") ? 409 : 400 }
    );
  }
}
