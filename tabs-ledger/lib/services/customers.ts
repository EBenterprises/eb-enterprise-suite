import { randomId } from "../security/ids";
import { db } from "../../database/db";

export type CustomerRecord = {
  id: string;
  organization_id: string;
  name: string;
  email: string | null;
  phone: string | null;
  notes: string | null;
  metadata_json: string;
  status: string;
  created_at: string;
  updated_at: string;
};

export function listCustomers(): CustomerRecord[] {
  return db.prepare(`
    SELECT *
    FROM customers
    ORDER BY name COLLATE NOCASE ASC, created_at ASC
  `).all() as unknown as CustomerRecord[];
}

export function getCustomer(id: string): CustomerRecord | null {
  return (db.prepare(`
    SELECT *
    FROM customers
    WHERE id = ?
    LIMIT 1
  `).get(id) as CustomerRecord | undefined) ?? null;
}

export function createCustomer(input: {
  name: string;
  email?: string | null;
  phone?: string | null;
  notes?: string | null;
  metadata?: Record<string, unknown>;
}): CustomerRecord {
  const name = input.name.trim();

  if (!name) {
    throw new Error("Customer name is required.");
  }

  const existing = db.prepare(`
    SELECT id
    FROM customers
    WHERE lower(name) = lower(?)
    LIMIT 1
  `).get(name) as { id: string } | undefined;

  if (existing) {
    throw new Error("A customer with that name already exists.");
  }

  const organization = db.prepare(`
    SELECT id
    FROM organizations
    ORDER BY created_at ASC
    LIMIT 1
  `).get() as { id: string } | undefined;

  if (!organization) {
    throw new Error("No organization is configured.");
  }

  const id = randomId("cus");
  const now = new Date().toISOString();

  db.prepare(`
    INSERT INTO customers (
      id,
      organization_id,
      name,
      email,
      phone,
      notes,
      metadata_json,
      status,
      created_at,
      updated_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, 'active', ?, ?)
  `).run(
    id,
    organization.id,
    name,
    input.email?.trim() || null,
    input.phone?.trim() || null,
    input.notes?.trim() || null,
    JSON.stringify(input.metadata ?? {}),
    now,
    now
  );

  return getCustomer(id)!;
}

export function customerBalance(customerId: string): {
  charges_cents: number;
  payments_cents: number;
  credits_cents: number;
  adjustments_cents: number;
  balance_cents: number;
} {
  const row = db.prepare(`
    SELECT
      COALESCE(SUM(
        CASE
          WHEN kind = 'charge' THEN amount_cents
          ELSE 0
        END
      ), 0) AS charges_cents,

      COALESCE(SUM(
        CASE
          WHEN kind = 'payment' THEN amount_cents
          ELSE 0
        END
      ), 0) AS payments_cents,

      COALESCE(SUM(
        CASE
          WHEN kind = 'credit' THEN amount_cents
          ELSE 0
        END
      ), 0) AS credits_cents,

      COALESCE(SUM(
        CASE
          WHEN kind = 'adjustment' THEN amount_cents
          ELSE 0
        END
      ), 0) AS adjustments_cents

    FROM ledger_entries
    WHERE customer_id = ?
  `).get(customerId) as {
    charges_cents: number;
    payments_cents: number;
    credits_cents: number;
    adjustments_cents: number;
  };

  const balance =
    row.charges_cents -
    row.payments_cents -
    row.credits_cents +
    row.adjustments_cents;

  return {
    ...row,
    balance_cents: balance,
  };
}
