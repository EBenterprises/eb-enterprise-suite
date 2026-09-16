import Link from "next/link";
import { listCustomers, customerBalance } from "@/lib/services/customers";

function money(cents: number): string {
  return new Intl.NumberFormat("en-CA", {
    style: "currency",
    currency: "CAD",
  }).format(cents / 100);
}

export const dynamic = "force-dynamic";

export default function CustomersPage() {
  const customers = listCustomers();

  return (
    <main className="page">
      <div className="page-header">
        <div>
          <div className="eyebrow">TABS® LEDGER</div>
          <h1>Customers</h1>
          <p className="muted">
            Customer accounts and recalculated balances.
          </p>
        </div>

        <div className="actions">
          <Link className="button" href="/">
            Dashboard
          </Link>
          <Link className="button primary" href="/customers/new">
            + Customer
          </Link>
        </div>
      </div>

      <section className="card">
        {customers.length === 0 ? (
          <div className="empty">
            <strong>No customers yet.</strong>
            <span>Create the first customer through the customer API.</span>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Customer</th>
                  <th>Status</th>
                  <th>Charges</th>
                  <th>Payments</th>
                  <th>Balance</th>
                  <th />
                </tr>
              </thead>

              <tbody>
                {customers.map((customer) => {
                  const balance = customerBalance(customer.id);

                  return (
                    <tr key={customer.id}>
                      <td>
                        <strong>{customer.name}</strong>
                        {customer.email && (
                          <div className="muted small">{customer.email}</div>
                        )}
                      </td>

                      <td>
                        <span className="badge">{customer.status}</span>
                      </td>

                      <td>{money(balance.charges_cents)}</td>
                      <td>{money(balance.payments_cents)}</td>

                      <td>
                        <strong>{money(balance.balance_cents)}</strong>
                      </td>

                      <td>
                        <Link
                          className="button small-button"
                          href={`/customers/${customer.id}`}
                        >
                          Open
                        </Link>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </main>
  );
}
