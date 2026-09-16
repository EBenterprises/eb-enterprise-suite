import { db } from "../../database/db";

export type ReconciliationIssue = {
  type: string;
  customer_id?: string;
  ledger_entry_id?: string;
  payment_id?: string;
  message: string;
};

export type ReconciliationResult = {
  ok: boolean;
  checked_at: string;
  customers_checked: number;
  ledger_entries_checked: number;
  allocations_checked: number;
  issues: ReconciliationIssue[];
};

export function reconcileLedger(): ReconciliationResult {
  const checkedAt = new Date().toISOString();
  const issues: ReconciliationIssue[] = [];

  const customers = db.prepare(`
    SELECT id
    FROM customers
    ORDER BY id
  `).all() as Array<{ id: string }>;

  const ledgerEntries = db.prepare(`
    SELECT
      id,
      customer_id,
      kind,
      amount_cents
    FROM ledger_entries
    ORDER BY id
  `).all() as Array<{
    id: string;
    customer_id: string;
    kind: string;
    amount_cents: number;
  }>;

  const allocations = db.prepare(`
    SELECT
      pa.id,
      pa.payment_id,
      pa.ledger_entry_id,
      pa.amount_cents,
      payment.customer_id AS payment_customer_id,
      charge.customer_id AS charge_customer_id,
      charge.kind AS charge_kind,
      payment.kind AS payment_kind,
      payment.amount_cents AS payment_amount_cents
    FROM payment_allocations pa
    INNER JOIN ledger_entries payment
      ON payment.id = pa.payment_id
    INNER JOIN ledger_entries charge
      ON charge.id = pa.ledger_entry_id
    ORDER BY pa.id
  `).all() as Array<{
    id: string;
    payment_id: string;
    ledger_entry_id: string;
    amount_cents: number;
    payment_customer_id: string;
    charge_customer_id: string;
    charge_kind: string;
    payment_kind: string;
    payment_amount_cents: number;
  }>;

  const ledgerIds = new Set(ledgerEntries.map((entry) => entry.id));

  for (const entry of ledgerEntries) {
    if (!entry.customer_id) {
      issues.push({
        type: "missing_customer",
        ledger_entry_id: entry.id,
        message: "Ledger entry has no customer.",
      });
    }

    if (!Number.isSafeInteger(entry.amount_cents)) {
      issues.push({
        type: "invalid_amount",
        ledger_entry_id: entry.id,
        message: "Ledger amount is not a safe integer.",
      });
    }

    if (entry.amount_cents <= 0) {
      issues.push({
        type: "non_positive_amount",
        ledger_entry_id: entry.id,
        message: "Ledger amount must be positive.",
      });
    }

    if (
      entry.kind !== "charge" &&
      entry.kind !== "payment" &&
      entry.kind !== "credit" &&
      entry.kind !== "adjustment"
    ) {
      issues.push({
        type: "unknown_kind",
        ledger_entry_id: entry.id,
        message: `Unknown ledger kind: ${entry.kind}`,
      });
    }
  }

  const allocationTotals = new Map<string, number>();

  for (const allocation of allocations) {
    if (!ledgerIds.has(allocation.payment_id)) {
      issues.push({
        type: "orphan_payment",
        payment_id: allocation.payment_id,
        message: "Allocation references a missing payment.",
      });
    }

    if (!ledgerIds.has(allocation.ledger_entry_id)) {
      issues.push({
        type: "orphan_charge",
        ledger_entry_id: allocation.ledger_entry_id,
        message: "Allocation references a missing charge.",
      });
    }

    if (allocation.payment_kind !== "payment") {
      issues.push({
        type: "invalid_payment_reference",
        payment_id: allocation.payment_id,
        message: "Allocation does not reference a payment ledger entry.",
      });
    }

    if (allocation.charge_kind !== "charge") {
      issues.push({
        type: "invalid_charge_reference",
        ledger_entry_id: allocation.ledger_entry_id,
        message: "Allocation does not reference a charge ledger entry.",
      });
    }

    if (allocation.payment_customer_id !== allocation.charge_customer_id) {
      issues.push({
        type: "cross_customer_allocation",
        payment_id: allocation.payment_id,
        ledger_entry_id: allocation.ledger_entry_id,
        message: "Payment allocation crosses customer accounts.",
      });
    }

    if (
      !Number.isSafeInteger(allocation.amount_cents) ||
      allocation.amount_cents <= 0
    ) {
      issues.push({
        type: "invalid_allocation",
        payment_id: allocation.payment_id,
        ledger_entry_id: allocation.ledger_entry_id,
        message: "Allocation amount is invalid.",
      });
    }

    allocationTotals.set(
      allocation.payment_id,
      (allocationTotals.get(allocation.payment_id) ?? 0) +
        allocation.amount_cents
    );

    const chargeAllocated = db.prepare(`
      SELECT COALESCE(SUM(amount_cents), 0) AS total
      FROM payment_allocations
      WHERE ledger_entry_id = ?
    `).get(allocation.ledger_entry_id) as { total: number };

    const charge = db.prepare(`
      SELECT amount_cents
      FROM ledger_entries
      WHERE id = ?
        AND kind = 'charge'
      LIMIT 1
    `).get(allocation.ledger_entry_id) as
      | { amount_cents: number }
      | undefined;

    if (
      charge &&
      chargeAllocated.total > charge.amount_cents
    ) {
      issues.push({
        type: "overallocated_charge",
        ledger_entry_id: allocation.ledger_entry_id,
        message:
          "Total allocations exceed the original charge amount.",
      });
    }
  }

  for (const [paymentId, allocated] of allocationTotals) {
    const payment = db.prepare(`
      SELECT amount_cents
      FROM ledger_entries
      WHERE id = ?
        AND kind = 'payment'
      LIMIT 1
    `).get(paymentId) as
      | { amount_cents: number }
      | undefined;

    if (payment && allocated > payment.amount_cents) {
      issues.push({
        type: "overallocated_payment",
        payment_id: paymentId,
        message:
          "Total allocations exceed the original payment amount.",
      });
    }
  }

  /*
   * Customer-level balance cross-check.
   *
   * This independently calculates:
   * charges - payments - credits + adjustments
   *
   * Payment allocations do NOT alter the financial balance.
   * They only determine which charges have been paid.
   */
  for (const customer of customers) {
    const result = db.prepare(`
      SELECT
        COALESCE(SUM(
          CASE WHEN kind = 'charge'
          THEN amount_cents ELSE 0 END
        ), 0) AS charges,

        COALESCE(SUM(
          CASE WHEN kind = 'payment'
          THEN amount_cents ELSE 0 END
        ), 0) AS payments,

        COALESCE(SUM(
          CASE WHEN kind = 'credit'
          THEN amount_cents ELSE 0 END
        ), 0) AS credits,

        COALESCE(SUM(
          CASE WHEN kind = 'adjustment'
          THEN amount_cents ELSE 0 END
        ), 0) AS adjustments

      FROM ledger_entries
      WHERE customer_id = ?
    `).get(customer.id) as {
      charges: number;
      payments: number;
      credits: number;
      adjustments: number;
    };

    const expected =
      result.charges -
      result.payments -
      result.credits +
      result.adjustments;

    if (!Number.isSafeInteger(expected)) {
      issues.push({
        type: "balance_overflow",
        customer_id: customer.id,
        message: "Calculated customer balance is not a safe integer.",
      });
    }
  }

  return {
    ok: issues.length === 0,
    checked_at: checkedAt,
    customers_checked: customers.length,
    ledger_entries_checked: ledgerEntries.length,
    allocations_checked: allocations.length,
    issues,
  };
}
