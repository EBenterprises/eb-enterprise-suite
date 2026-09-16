import Link from "next/link";
import { listCustomers } from "@/lib/services/customers";
import { listPayments } from "@/lib/services/payments";

function money(cents: number) {
  return new Intl.NumberFormat("en-CA", {
    style: "currency",
    currency: "CAD",
  }).format(Number(cents) / 100);
}

export const dynamic = "force-dynamic";

export default function PaymentsPage() {
  const customers = listCustomers();
  const payments = listPayments();

  const names = new Map(
    customers.map((customer) => [customer.id, customer.name])
  );

  const total = payments.reduce(
    (sum, payment) => sum + Number(payment.amount_cents),
    0
  );

  return (
    <main className="page">
      <div className="page-header">
        <div>
          <div className="eyebrow">TABS® LEDGER</div>
          <h1>Payments</h1>
          <p className="muted">
            Payments are immutable ledger entries with FIFO allocations.
          </p>
        </div>

        <div className="actions">
          <Link className="button" href="/">
            Dashboard
          </Link>
          <Link className="button primary" href="/payments/new">
            + Payment
          </Link>
        </div>
      </div>

      <section className="stats-grid">
        <div className="stat-card">
          <span>Payments</span>
          <strong>{payments.length}</strong>
        </div>

        <div className="stat-card">
          <span>Total Received</span>
          <strong>{money(total)}</strong>
        </div>
      </section>

      <section className="card">
        {payments.length === 0 ? (
          <div className="empty">
            <strong>No payments recorded.</strong>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Date / Time</th>
                  <th>Customer</th>
                  <th>Amount</th>
                  <th>Location</th>
                  <th>Payment ID</th>
                </tr>
              </thead>

              <tbody>
                {payments.map((payment) => (
                  <tr key={payment.id}>
                    <td>
                      {new Date(payment.occurred_at).toLocaleString(
                        "en-CA"
                      )}
                    </td>
                    <td>
                      {names.get(payment.customer_id) ||
                        payment.customer_id}
                    </td>
                    <td>
                      <strong>{money(payment.amount_cents)}</strong>
                    </td>
                    <td>{payment.location || "—"}</td>
                    <td className="mono">{payment.id}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </main>
  );
}
