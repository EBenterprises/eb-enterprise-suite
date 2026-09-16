import { bootstrap } from "@/core/bootstrap";
import { getDb } from "@/database/db";

function money(cents: number) {
  return new Intl.NumberFormat(
    "en-CA",
    {
      style: "currency",
      currency: "CAD"
    }
  ).format(cents / 100);
}

export default function Home() {
  bootstrap();

  const db = getDb();

  const organization =
    db.prepare(`
      SELECT id, name
      FROM organizations
      ORDER BY created_at
      LIMIT 1
    `).get() as {
      id: string;
      name: string;
    };

  const totals =
    db.prepare(`
      SELECT
        COUNT(DISTINCT c.id) customers,

        COALESCE(SUM(
          CASE
            WHEN l.kind = 'charge'
            THEN l.amount_cents
            ELSE 0
          END
        ), 0) charges,

        COALESCE(SUM(
          CASE
            WHEN l.kind = 'payment'
            THEN l.amount_cents
            ELSE 0
          END
        ), 0) payments,

        COALESCE(SUM(
          CASE
            WHEN l.kind = 'credit'
            THEN l.amount_cents
            ELSE 0
          END
        ), 0) credits

      FROM customers c
      LEFT JOIN ledger_entries l
        ON l.customer_id = c.id
      WHERE c.organization_id = ?
    `).get(organization.id) as {
      customers: number;
      charges: number;
      payments: number;
      credits: number;
    };

  const balance =
    totals.charges -
    totals.payments -
    totals.credits;

  return (
    <main className="shell">
      <header>
        <div>
          <div className="eyebrow">
            EB ENTERPRISES®
          </div>

          <h1>Tabs® Ledger</h1>

          <p>
            {organization.name}
            {" · "}
            local-first transaction command center
          </p>
        </div>

        <div className="status">
          <span className="dot" />
          Operational
        </div>
      </header>

      <section className="grid">
        <div className="card">
          <span>Customers</span>
          <strong>{totals.customers}</strong>
        </div>

        <div className="card">
          <span>Total charges</span>
          <strong>
            {money(totals.charges)}
          </strong>
        </div>

        <div className="card">
          <span>Total payments</span>
          <strong>
            {money(totals.payments)}
          </strong>
        </div>

        <div className="card">
          <span>Outstanding</span>
          <strong>
            {money(balance)}
          </strong>
        </div>
      </section>
    </main>
  );
}
