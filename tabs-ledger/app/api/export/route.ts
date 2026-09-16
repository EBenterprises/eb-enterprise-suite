import { NextResponse } from "next/server";
import { db } from "@/database/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const organizations = db.prepare(`
      SELECT * FROM organizations
      ORDER BY created_at ASC
    `).all();

    const customers = db.prepare(`
      SELECT * FROM customers
      ORDER BY created_at ASC
    `).all();

    const ledgerEntries = db.prepare(`
      SELECT * FROM ledger_entries
      ORDER BY occurred_at ASC, created_at ASC, id ASC
    `).all();

    const allocations = db.prepare(`
      SELECT * FROM payment_allocations
      ORDER BY created_at ASC, id ASC
    `).all();

    const auditEvents = db.prepare(`
      SELECT * FROM audit_events
      ORDER BY created_at ASC, id ASC
    `).all();

    return NextResponse.json({
      export_version: 1,
      exported_at: new Date().toISOString(),
      source: "tabs-ledger",
      organizations,
      customers,
      ledger_entries: ledgerEntries,
      payment_allocations: allocations,
      audit_events: auditEvents,
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Export failed.",
      },
      { status: 500 }
    );
  }
}
