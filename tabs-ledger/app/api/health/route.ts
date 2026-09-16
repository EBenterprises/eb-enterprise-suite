import { bootstrap } from "@/core/bootstrap";
import {
  databasePath,
  getDb
} from "@/database/db";

export const runtime = "nodejs";

export async function GET() {
  try {
    bootstrap();

    const db = getDb();

    const counts = db.prepare(`
      SELECT
        (SELECT COUNT(*) FROM customers) customers,
        (SELECT COUNT(*) FROM ledger_entries) ledger,
        (SELECT COUNT(*) FROM audit_events) audit
    `).get();

    return Response.json({
      status: "operational",
      runtime: process.version,
      database: databasePath(),
      timestamp:
        new Date().toISOString(),
      counts
    });
  } catch (error) {
    return Response.json(
      {
        status: "failed",
        error:
          error instanceof Error
            ? error.message
            : String(error)
      },
      { status: 500 }
    );
  }
}
