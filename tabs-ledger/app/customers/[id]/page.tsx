import Link from "next/link";
import { notFound } from "next/navigation";
import {
  customerBalance,
  getCustomer,
} from "@/lib/services/customers";

function money(cents: number): string {
  return new Intl.NumberFormat("en-CA", {
    style: "currency",
    currency: "CAD",
  }).format(cents / 100);
}

export const dynamic = "force-dynamic";

export default async function CustomerPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const customer = getCustomer(id);

  if (!customer) {
    notFound();
  }

  const balance = customerBalance(customer.id);

  return (
    <main className="page">
      <div className="page-header">
        <div>
          <div className="eyebrow">CUSTOMER ACCOUNT</div>
          <h1>{customer.name}</h1>
          <p className="muted">
            Created {new Date(customer.created_at).toLocaleString("en-CA")}
          </p>
        </div>

        <Link className="button" href="/customers">
          ← Customers
        </Link>
      </div>

      <section className="stats-grid">
        <div className="stat-card">
          <span>Charges</span>
          <strong>{money(balance.charges_cents)}</strong>
        </div>

        <div className="stat-card">
          <span>Payments</span>
          <strong>{money(balance.payments_cents)}</strong>
        </div>

        <div className="stat-card">
          <span>Credits</span>
          <strong>{money(balance.credits_cents)}</strong>
        </div>

        <div className="stat-card">
          <span>Balance Due</span>
          <strong>{money(balance.balance_cents)}</strong>
        </div>
      </section>

      <section className="card">
        <h2>Account information</h2>

        <dl className="details">
          <div>
            <dt>Status</dt>
            <dd>{customer.status}</dd>
          </div>

          <div>
            <dt>Email</dt>
            <dd>{customer.email || "—"}</dd>
          </div>

          <div>
            <dt>Phone</dt>
            <dd>{customer.phone || "—"}</dd>
          </div>

          <div>
            <dt>Notes</dt>
            <dd>{customer.notes || "—"}</dd>
          </div>

          <div>
            <dt>Customer ID</dt>
            <dd className="mono">{customer.id}</dd>
          </div>
        </dl>
      </section>

      <section className="card">
        <h2>Ledger</h2>
        <p className="muted">
          Transaction entry and immutable ledger history are added in the next
          stage.
        </p>
      </section>
    </main>
  );
}
