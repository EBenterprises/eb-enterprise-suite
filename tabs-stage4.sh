#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

APP="${TABS_APP_DIR:-$HOME/tabs-ledger}"

mkdir -p "$APP/app/api/health"

cat > "$APP/app/layout.tsx" <<'__LAYOUT__'
import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Tabs® Ledger",
  description:
    "Local-first transaction and customer ledger platform"
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
__LAYOUT__

cat > "$APP/app/api/health/route.ts" <<'__HEALTH__'
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
__HEALTH__

cat > "$APP/app/globals.css" <<'__CSS__'
:root {
  --bg: #090a0c;
  --panel: #111318;
  --panel2: #171a20;
  --line: #292d35;
  --text: #f2f0ea;
  --muted: #949aa5;
  --gold: #d6b46a;
  --teal: #4ec7bd;
}

* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  min-height: 100%;
}

body {
  background: var(--bg);
  color: var(--text);
  font-family:
    Inter,
    system-ui,
    -apple-system,
    BlinkMacSystemFont,
    "Segoe UI",
    sans-serif;
}

.shell {
  width: min(1400px, calc(100% - 24px));
  margin: auto;
  padding: 28px 0 60px;
}

header {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  align-items: flex-start;
  margin-bottom: 25px;
}

.eyebrow {
  color: var(--gold);
  font-size: 11px;
  font-weight: 800;
  letter-spacing: .16em;
}

h1 {
  margin: 6px 0;
  font-size: clamp(30px, 6vw, 50px);
  letter-spacing: -.045em;
}

p {
  color: var(--muted);
}

.status {
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 8px 12px;
  font-size: 12px;
  color: var(--muted);
}

.dot {
  display: inline-block;
  width: 7px;
  height: 7px;
  margin-right: 7px;
  border-radius: 50%;
  background: var(--teal);
}

.grid {
  display: grid;
  grid-template-columns:
    repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.card {
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: 15px;
  padding: 20px;
}

.card span {
  color: var(--muted);
  font-size: 12px;
}

.card strong {
  display: block;
  margin-top: 8px;
  font-size: 27px;
}

@media (max-width: 700px) {
  .grid {
    grid-template-columns:
      repeat(2, minmax(0, 1fr));
  }

  header {
    flex-direction: column;
  }
}
__CSS__

cat > "$APP/app/page.tsx" <<'__PAGE__'
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
__PAGE__

cd "$APP"

npm run typecheck
npm run build
npm run db:verify

printf '\n'
printf '\033[32m✓\033[0m TABS® FOUNDATION VERIFIED\n'
printf '\n'
printf 'Start:\n'
printf '  cd "%s"\n' "$APP"
printf '  npm run dev\n'
printf '\n'
printf 'Health:\n'
printf '  curl http://127.0.0.1:3000/api/health\n'
printf '\n'
printf 'Verification:\n'
printf '  npm run db:verify\n'
printf '  npm run db:reconcile\n'
printf '  npm run db:backup\n'
