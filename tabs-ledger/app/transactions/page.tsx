import Link from "next/link";
import { listTransactions, transactionStats } from "@/lib/services/transactions";
import { listCustomers } from "@/lib/services/customers";

function money(cents: number) {
  return new Intl.NumberFormat("en-CA", {
    style: "currency",
    currency: "CAD",
  }).format(cents / 100);
}

export const dynamic = "force-dynamic";

export default function TransactionsPage() {
  const transactions = listTransactions();
  const customers = listCustomers();
  const stats = transactionStats();

  const customerNames = new Map(
    customers.map((customer) => [customer.id, customer.name])
  );

  return (
    <main className="page">
      <nav className="actions" aria-label="Primary"><a className="button" href="/payments">Payments</a></nav>
      <div className="page-header">
        <div>
          <div className="eyebrow">TABS® LEDGER</div>
          <h1>Transactions</h1>
          <p className="muted">
            Immutable charge entries recorded against customer accounts.
          </p>
        </div>

        <div className="actions">
          <Link className="button" href="/">
            Dashboard
          </Link>
          <Link className="button primary" href="/transactions/new">
            + Transaction
          </Link>
        </div>
      </div>

      <section className="stats-grid">
        <div className="stat-card">
          <span>Transactions</span>
          <strong>{stats.transaction_count}</strong>
        </div>

        <div className="stat-card">
          <span>Total Quantity</span>
          <strong>{stats.total_quantity}</strong>
        </div>

        <div className="stat-card">
          <span>Total Charges</span>
          <strong>{money(stats.total_amount_cents)}</strong>
        </div>
      </section>

      <section className="card">
        {transactions.length === 0 ? (
          <div className="empty">
            <strong>No transactions recorded.</strong>
            <span>Create a transaction to begin the ledger history.</span>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Date / Time</th>
                  <th>Customer</th>
                  <th>Item</th>
                  <th>Quantity</th>
                  <th>Location</th>
                  <th>Amount</th>
                  <th>Transaction ID</th>
                </tr>
              </thead>

              <tbody>
                {transactions.map((transaction) => (
                  <tr key={transaction.id}>
                    <td>
                      {new Date(transaction.occurred_at).toLocaleString(
                        "en-CA"
                      )}
                    </td>
                    <td>
                      {customerNames.get(transaction.customer_id) ||
                        transaction.customer_id}
                    </td>
                    <td>{transaction.item || "—"}</td>
                    <td>{transaction.quantity ?? "—"}</td>
                    <td>{transaction.location || "—"}</td>
                    <td>
                      <strong>{money(transaction.amount_cents)}</strong>
                    </td>
                    <td className="mono">{transaction.id}</td>
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
