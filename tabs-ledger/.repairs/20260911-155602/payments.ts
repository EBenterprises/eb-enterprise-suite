import { randomId } from "../security/ids";
import { db } from "../../database/db";

type ChargeRow = {
  id: string;
  amount_cents: number;
  occurred_at: string;
  location: string | null;
  item: string | null;
  quantity: number | null;
};

type PaymentRecord = {
  id: string;
  organization_id: string;
  customer_id: string;
  kind: string;
  amount_cents: number;
  occurred_at: string;
  location: string | null;
  note: string | null;
  metadata_json: string;
  created_at: string;
};

function requireCustomer(customerId: string) {
  const customer = db.prepare(`
    SELECT id, organization_id
    FROM customers
    WHERE id = ?
    LIMIT 1
  `).get(customerId) as
    | { id: string; organization_id: string }
    | undefined;

  if (!customer) {
    throw new Error("Customer not found.");
  }

  return customer;
}

function getPayment(id: string): PaymentRecord | null {
  return (db.prepare(`
    SELECT
      id,
      organization_id,
      customer_id,
      kind,
      amount_cents,
      occurred_at,
      location,
      note,
      metadata_json,
      created_at
    FROM ledger_entries
    WHERE id = ?
    LIMIT 1
  `).get(id) as PaymentRecord | undefined) ?? null;
}

/**
 * Returns the currently outstanding amount for each charge.
 * Payments are allocated oldest-first.
 */
function outstandingCharges(customerId: string): Array<ChargeRow & {
  outstanding_cents: number;
}> {
  const charges = db.prepare(`
    SELECT
      le.id,
      le.amount_cents,
      le.occurred_at,
      le.location,
      le.item,
      le.quantity
    FROM ledger_entries le
    WHERE le.customer_id = ?
      AND le.kind = 'charge'
    ORDER BY le.occurred_at ASC, le.created_at ASC, le.id ASC
  `).all(customerId) as unknown as ChargeRow[];

  return charges.map((charge) => {
    const allocated = db.prepare(`
      SELECT COALESCE(SUM(amount_cents), 0) AS allocated_cents
      FROM payment_allocations
      WHERE ledger_entry_id = ?
    `).get(charge.id) as { allocated_cents: number };

    return {
      ...charge,
      outstanding_cents: Math.max(
        0,
        charge.amount_cents - allocated.allocated_cents
      ),
    };
  });
}

export function recordPayment(input: {
  customer_id: string;
  amount_cents: number;
  occurred_at?: string;
  location?: string | null;
  note?: string | null;
}) {
  const customer = requireCustomer(input.customer_id);

  if (!Number.isSafeInteger(input.amount_cents) || input.amount_cents <= 0) {
    throw new Error("Payment must be a positive integer number of cents.");
  }

  const occurredAt = input.occurred_at
    ? new Date(input.occurred_at).toISOString()
    : new Date().toISOString();

  const now = new Date().toISOString();

  const result = db.transaction(() => {
    const paymentId = randomId("pay");

    /*
     * The payment itself is an immutable ledger entry.
     * Allocations are separate records so the original payment remains intact.
     */
    db.prepare(`
      INSERT INTO ledger_entries (
        id,
        organization_id,
        customer_id,
        kind,
        amount_cents,
        occurred_at,
        location,
        item,
        quantity,
        note,
        metadata_json,
        created_at
      )
      VALUES (?, ?, ?, 'payment', ?, ?, ?, NULL, NULL, ?, ?, ?)
    `).run(
      paymentId,
      customer.organization_id,
      customer.id,
      input.amount_cents,
      occurredAt,
      input.location?.trim() || null,
      input.note?.trim() || null,
      JSON.stringify({
        source: "tabs-ledger",
        schema_version: 1,
        allocation_policy: "fifo",
      }),
      now
    );

    let remaining = input.amount_cents;
    const allocations: Array<{
      charge_id: string;
      amount_cents: number;
    }> = [];

    /*
     * FIFO:
     * oldest outstanding charge first.
     */
    for (const charge of outstandingCharges(customer.id)) {
      if (remaining <= 0) break;
      if (charge.outstanding_cents <= 0) continue;

      const allocation = Math.min(
        remaining,
        charge.outstanding_cents
      );

      db.prepare(`
        INSERT INTO payment_allocations (
          id,
          payment_id,
          ledger_entry_id,
          amount_cents,
          created_at
        )
        VALUES (?, ?, ?, ?, ?)
      `).run(
        randomId("alloc"),
        paymentId,
        charge.id,
        allocation,
        now
      );

      allocations.push({
        charge_id: charge.id,
        amount_cents: allocation,
      });

      remaining -= allocation;
    }

    return {
      payment: getPayment(paymentId)!,
      allocations,
      unapplied_cents: remaining,
    };
  })();

  return result;
}

export function listPayments(customerId?: string) {
  const rows = customerId
    ? db.prepare(`
        SELECT
          id,
          organization_id,
          customer_id,
          kind,
          amount_cents,
          occurred_at,
          location,
          note,
          metadata_json,
          created_at
        FROM ledger_entries
        WHERE customer_id = ?
          AND kind = 'payment'
        ORDER BY occurred_at DESC, created_at DESC
      `).all(customerId)
    : db.prepare(`
        SELECT
          id,
          organization_id,
          customer_id,
          kind,
          amount_cents,
          occurred_at,
          location,
          note,
          metadata_json,
          created_at
        FROM ledger_entries
        WHERE kind = 'payment'
        ORDER BY occurred_at DESC, created_at DESC
      `).all();

  return rows;
}

export function customerPaymentSummary(customerId: string) {
  requireCustomer(customerId);

  const totals = db.prepare(`
    SELECT
      COALESCE(SUM(amount_cents), 0) AS total_payments_cents
    FROM ledger_entries
    WHERE customer_id = ?
      AND kind = 'payment'
  `).get(customerId) as {
    total_payments_cents: number;
  };

  const allocations = db.prepare(`
    SELECT
      COALESCE(SUM(pa.amount_cents), 0) AS allocated_cents
    FROM payment_allocations pa
    INNER JOIN ledger_entries payment
      ON payment.id = pa.payment_id
    WHERE payment.customer_id = ?
  `).get(customerId) as {
    allocated_cents: number;
  };

  return {
    total_payments_cents: totals.total_payments_cents,
    allocated_cents: allocations.allocated_cents,
    unapplied_cents:
      totals.total_payments_cents - allocations.allocated_cents,
  };
}
