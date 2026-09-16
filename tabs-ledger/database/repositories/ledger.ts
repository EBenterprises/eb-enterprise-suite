import type { DatabaseSync } from "node:sqlite";
import { newId } from "@/core/security/ids";
import type {
  LedgerEntry,
  LedgerKind
} from "@/types/domain";

export function createLedgerEntry(
  db: DatabaseSync,
  input: {
    organizationId: string;
    customerId: string;
    kind: LedgerKind;
    amountCents: number;
    quantityText?: string | null;
    item?: string | null;
    location?: string | null;
    description?: string | null;
    effectiveAt: string;
    source?: string;
    sourceReference?: string | null;
    metadata?: Record<string, unknown>;
  }
): LedgerEntry {
  if (
    !Number.isSafeInteger(input.amountCents) ||
    input.amountCents < 0
  ) {
    throw new Error(
      "amountCents must be a non-negative safe integer."
    );
  }

  const id = newId("txn");
  const now = new Date().toISOString();

  db.prepare(`
    INSERT INTO ledger_entries (
      id,
      organization_id,
      customer_id,
      kind,
      amount_cents,
      quantity_text,
      item,
      location,
      description,
      effective_at,
      created_at,
      source,
      source_reference,
      metadata_json
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    input.organizationId,
    input.customerId,
    input.kind,
    input.amountCents,
    input.quantityText ?? null,
    input.item ?? null,
    input.location ?? null,
    input.description ?? null,
    input.effectiveAt,
    now,
    input.source ?? "app",
    input.sourceReference ?? null,
    JSON.stringify(input.metadata ?? {})
  );

  return getLedgerEntry(db, id)!;
}

export function getLedgerEntry(
  db: DatabaseSync,
  id: string
): LedgerEntry | null {
  const row = db.prepare(`
    SELECT *
    FROM ledger_entries
    WHERE id = ?
  `).get(id) as any;

  if (!row) return null;

  return {
    id: row.id,
    organizationId: row.organization_id,
    customerId: row.customer_id,
    kind: row.kind,
    amountCents: row.amount_cents,
    quantityText: row.quantity_text,
    item: row.item,
    location: row.location,
    description: row.description,
    effectiveAt: row.effective_at,
    createdAt: row.created_at,
    source: row.source,
    sourceReference: row.source_reference,
    metadata: JSON.parse(row.metadata_json),
    reversedEntryId: row.reversed_entry_id
  };
}

export function listLedgerEntries(
  db: DatabaseSync,
  customerId: string
): LedgerEntry[] {
  const rows = db.prepare(`
    SELECT *
    FROM ledger_entries
    WHERE customer_id = ?
    ORDER BY
      effective_at ASC,
      created_at ASC,
      id ASC
  `).all(customerId) as any[];

  return rows.map((row) => ({
    id: row.id,
    organizationId: row.organization_id,
    customerId: row.customer_id,
    kind: row.kind,
    amountCents: row.amount_cents,
    quantityText: row.quantity_text,
    item: row.item,
    location: row.location,
    description: row.description,
    effectiveAt: row.effective_at,
    createdAt: row.created_at,
    source: row.source,
    sourceReference: row.source_reference,
    metadata: JSON.parse(row.metadata_json),
    reversedEntryId: row.reversed_entry_id
  }));
}

export function customerTotals(
  db: DatabaseSync,
  customerId: string
) {
  const row = db.prepare(`
    SELECT
      COALESCE(SUM(
        CASE
          WHEN kind = 'charge'
          THEN amount_cents
          ELSE 0
        END
      ), 0) charges,

      COALESCE(SUM(
        CASE
          WHEN kind = 'payment'
          THEN amount_cents
          ELSE 0
        END
      ), 0) payments,

      COALESCE(SUM(
        CASE
          WHEN kind = 'credit'
          THEN amount_cents
          ELSE 0
        END
      ), 0) credits,

      COALESCE(SUM(
        CASE
          WHEN kind = 'adjustment'
          THEN amount_cents
          WHEN kind = 'reversal'
          THEN -amount_cents
          ELSE 0
        END
      ), 0) adjustments,

      COUNT(*) transaction_count

    FROM ledger_entries
    WHERE customer_id = ?
  `).get(customerId) as any;

  return {
    chargesCents: row.charges,
    paymentsCents: row.payments,
    creditsCents: row.credits,
    adjustmentsCents: row.adjustments,
    transactionCount: row.transaction_count,
    balanceCents:
      row.charges -
      row.payments -
      row.credits +
      row.adjustments
  };
}
