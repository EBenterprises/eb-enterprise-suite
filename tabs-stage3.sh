#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

APP="${TABS_APP_DIR:-$HOME/tabs-ledger}"

cat > "$APP/database/repositories/customers.ts" <<'__CUSTOMERS__'
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
__CUSTOMERS__

cat > "$APP/database/repositories/ledger.ts" <<'__LEDGER__'
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
__LEDGER__

cat > "$APP/core/application/audit.ts" <<'__AUDIT__'
import type { DatabaseSync } from "node:sqlite";
import { newId } from "@/core/security/ids";
import { sha256 } from "@/core/integrity/hash";

export function audit(
  db: DatabaseSync,
  input: {
    organizationId: string;
    entityType: string;
    entityId: string;
    action: string;
    actor?: string;
    payload: unknown;
  }
) {
  const previous = db.prepare(`
    SELECT event_hash
    FROM audit_events
    WHERE organization_id = ?
    ORDER BY occurred_at DESC, id DESC
    LIMIT 1
  `).get(input.organizationId) as {
    event_hash: string;
  } | undefined;

  const id = newId("aud");
  const occurredAt =
    new Date().toISOString();

  const previousHash =
    previous?.event_hash ?? null;

  const eventHash = sha256({
    id,
    organizationId: input.organizationId,
    entityType: input.entityType,
    entityId: input.entityId,
    action: input.action,
    actor: input.actor ?? "system",
    occurredAt,
    payload: input.payload,
    previousHash
  });

  db.prepare(`
    INSERT INTO audit_events (
      id,
      organization_id,
      entity_type,
      entity_id,
      action,
      actor,
      occurred_at,
      payload_json,
      previous_hash,
      event_hash
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    input.organizationId,
    input.entityType,
    input.entityId,
    input.action,
    input.actor ?? "system",
    occurredAt,
    JSON.stringify(input.payload),
    previousHash,
    eventHash
  );
}
__AUDIT__

cat > "$APP/core/application/ledger.ts" <<'__APPLEDGER__'
import { getDb, transaction } from "@/database/db";
import {
  createLedgerEntry,
  customerTotals
} from "@/database/repositories/ledger";
import { getCustomer } from "@/database/repositories/customers";
import { audit } from "./audit";
import type { LedgerKind } from "@/types/domain";

export function recordLedgerEntry(input: {
  organizationId: string;
  customerId: string;
  kind: LedgerKind;
  amountCents: number;
  quantityText?: string | null;
  item?: string | null;
  location?: string | null;
  description?: string | null;
  effectiveAt?: string;
  source?: string;
  sourceReference?: string | null;
  metadata?: Record<string, unknown>;
  actor?: string;
}) {
  return transaction(() => {
    const db = getDb();

    const customer =
      getCustomer(db, input.customerId);

    if (!customer) {
      throw new Error("Customer not found.");
    }

    if (
      customer.organizationId !==
      input.organizationId
    ) {
      throw new Error(
        "Customer organization mismatch."
      );
    }

    const entry = createLedgerEntry(db, {
      ...input,
      effectiveAt:
        input.effectiveAt ??
        new Date().toISOString()
    });

    audit(db, {
      organizationId: input.organizationId,
      entityType: "ledger_entry",
      entityId: entry.id,
      action: "created",
      actor: input.actor,
      payload: entry
    });

    return entry;
  });
}

export function getCustomerBalance(
  customerId: string
) {
  return customerTotals(
    getDb(),
    customerId
  );
}
__APPLEDGER__

cat > "$APP/scripts/db-verify.mjs" <<'__VERIFY__'
import {
  existsSync,
  createReadStream
} from "node:fs";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";

const dbPath =
  process.env.TABS_DB_PATH ||
  join(
    process.cwd(),
    "data",
    "tabs.sqlite"
  );

if (!existsSync(dbPath)) {
  console.log("STATUS=NOT_INITIALIZED");
  process.exit(0);
}

const db = new DatabaseSync(dbPath);

const integrity =
  db.prepare(
    "PRAGMA integrity_check"
  ).get();

const foreignKeys =
  db.prepare(
    "PRAGMA foreign_key_check"
  ).all();

if (integrity.integrity_check !== "ok") {
  console.error(
    "DATABASE_INTEGRITY=FAIL"
  );
  process.exit(1);
}

if (foreignKeys.length !== 0) {
  console.error(
    "FOREIGN_KEYS=FAIL"
  );
  process.exit(1);
}

const counts = db.prepare(`
  SELECT
    (SELECT COUNT(*) FROM customers) customers,
    (SELECT COUNT(*) FROM ledger_entries) ledger,
    (SELECT COUNT(*) FROM audit_events) audit
`).get();

console.log(
  `CUSTOMERS=${counts.customers}`
);

console.log(
  `LEDGER_ENTRIES=${counts.ledger}`
);

console.log(
  `AUDIT_EVENTS=${counts.audit}`
);

console.log("DATABASE_INTEGRITY=PASS");
console.log("FOREIGN_KEYS=PASS");
console.log("STATUS=PASS");

void createReadStream;
__VERIFY__

cd "$APP"

npm run typecheck

printf '\n'
printf '\033[32m✓\033[0m STAGE 3 COMPLETE\n'
printf 'Run Stage 4:\n'
printf '  bash ~/tabs-stage4.sh\n'
