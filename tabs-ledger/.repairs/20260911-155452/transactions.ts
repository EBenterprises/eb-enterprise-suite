import { randomId } from "@/lib/security/ids";
import { db } from "@/database/db";

export type TransactionInput = {
  customer_id: string;
  occurred_at?: string;
  location?: string | null;
  item?: string | null;
  quantity?: number | null;
  amount_cents: number;
  note?: string | null;
};

export type TransactionRecord = {
  id: string;
  organization_id: string;
  customer_id: string;
  kind: string;
  amount_cents: number;
  occurred_at: string;
  location: string | null;
  item: string | null;
  quantity: number | null;
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

export function createCharge(input: TransactionInput): TransactionRecord {
  const customer = requireCustomer(input.customer_id);

  if (!Number.isSafeInteger(input.amount_cents) || input.amount_cents <= 0) {
    throw new Error("Amount must be a positive integer number of cents.");
  }

  if (
    input.quantity !== undefined &&
    input.quantity !== null &&
    (!Number.isFinite(input.quantity) || input.quantity <= 0)
  ) {
    throw new Error("Quantity must be greater than zero.");
  }

  const id = randomId("txn");
  const now = new Date().toISOString();
  const occurredAt = input.occurred_at
    ? new Date(input.occurred_at).toISOString()
    : now;

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
    VALUES (?, ?, ?, 'charge', ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    customer.organization_id,
    customer.id,
    input.amount_cents,
    occurredAt,
    input.location?.trim() || null,
    input.item?.trim() || null,
    input.quantity ?? null,
    input.note?.trim() || null,
    JSON.stringify({
      source: "tabs-ledger",
      schema_version: 1,
    }),
    now
  );

  return getTransaction(id)!;
}

export function getTransaction(id: string): TransactionRecord | null {
  return (db.prepare(`
    SELECT
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
    FROM ledger_entries
    WHERE id = ?
    LIMIT 1
  `).get(id) as TransactionRecord | undefined) ?? null;
}

export function listTransactions(customerId?: string): TransactionRecord[] {
  if (customerId) {
    return db.prepare(`
      SELECT
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
      FROM ledger_entries
      WHERE customer_id = ?
      ORDER BY occurred_at DESC, created_at DESC
    `).all(customerId) as unknown as TransactionRecord[];
  }

  return db.prepare(`
    SELECT
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
    FROM ledger_entries
    ORDER BY occurred_at DESC, created_at DESC
  `).all() as unknown as TransactionRecord[];
}

export function transactionStats(customerId?: string) {
  const where = customerId ? "WHERE customer_id = ?" : "";
  const params = customerId ? [customerId] : [];

  const row = db.prepare(`
    SELECT
      COUNT(*) AS transaction_count,
      COALESCE(SUM(quantity), 0) AS total_quantity,
      COALESCE(SUM(amount_cents), 0) AS total_amount_cents
    FROM ledger_entries
    ${where}
      ${customerId ? "AND kind = 'charge'" : "WHERE kind = 'charge'"}
  `).get(...params) as {
    transaction_count: number;
    total_quantity: number;
    total_amount_cents: number;
  };

  return row;
}
