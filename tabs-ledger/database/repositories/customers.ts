import type { DatabaseSync } from "node:sqlite";
import { newId } from "@/core/security/ids";
import type { Customer } from "@/types/domain";

type Row = {
  id: string;
  organization_id: string;
  display_name: string;
  status: "active" | "archived";
  metadata_json: string;
  created_at: string;
  updated_at: string;
};

function map(row: Row): Customer {
  return {
    id: row.id,
    organizationId: row.organization_id,
    displayName: row.display_name,
    status: row.status,
    metadata: JSON.parse(row.metadata_json),
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}

export function createCustomer(
  db: DatabaseSync,
  input: {
    organizationId: string;
    displayName: string;
    metadata?: Record<string, unknown>;
  }
) {
  const name = input.displayName.trim();

  if (!name) {
    throw new Error("Customer name is required.");
  }

  const id = newId("cus");
  const now = new Date().toISOString();

  db.prepare(`
    INSERT INTO customers (
      id,
      organization_id,
      display_name,
      status,
      metadata_json,
      created_at,
      updated_at
    )
    VALUES (?, ?, ?, 'active', ?, ?, ?)
  `).run(
    id,
    input.organizationId,
    name,
    JSON.stringify(input.metadata ?? {}),
    now,
    now
  );

  return getCustomer(db, id)!;
}

export function getCustomer(
  db: DatabaseSync,
  id: string
) {
  const row = db.prepare(`
    SELECT *
    FROM customers
    WHERE id = ?
  `).get(id) as Row | undefined;

  return row ? map(row) : null;
}

export function listCustomers(
  db: DatabaseSync,
  organizationId: string
) {
  const rows = db.prepare(`
    SELECT *
    FROM customers
    WHERE organization_id = ?
    ORDER BY
      CASE
        WHEN status = 'active' THEN 0
        ELSE 1
      END,
      lower(display_name)
  `).all(organizationId) as unknown as Row[];

  return rows.map(map);
}
