#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

APP="${TABS_APP_DIR:-$HOME/tabs-ledger}"

mkdir -p \
  "$APP/database/migrations" \
  "$APP/database/repositories" \
  "$APP/core/application" \
  "$APP/core/integrity" \
  "$APP/core/security" \
  "$APP/core/serialization" \
  "$APP/types" \
  "$APP/scripts"

cat > "$APP/database/schema.sql" <<'__SCHEMA__'
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = FULL;

CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  applied_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS organizations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  metadata_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (organization_id)
    REFERENCES organizations(id)
);

CREATE INDEX IF NOT EXISTS idx_customers_org
ON customers(organization_id);

CREATE TABLE IF NOT EXISTS ledger_entries (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  quantity_text TEXT,
  item TEXT,
  location TEXT,
  description TEXT,
  effective_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'app',
  source_reference TEXT,
  metadata_json TEXT NOT NULL DEFAULT '{}',
  reversed_entry_id TEXT,
  FOREIGN KEY (organization_id)
    REFERENCES organizations(id),
  FOREIGN KEY (customer_id)
    REFERENCES customers(id),
  FOREIGN KEY (reversed_entry_id)
    REFERENCES ledger_entries(id)
);

CREATE INDEX IF NOT EXISTS idx_ledger_customer
ON ledger_entries(customer_id, effective_at);

CREATE INDEX IF NOT EXISTS idx_ledger_org
ON ledger_entries(organization_id, effective_at);

CREATE TABLE IF NOT EXISTS payment_allocations (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  payment_entry_id TEXT NOT NULL,
  charge_entry_id TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (organization_id)
    REFERENCES organizations(id),
  FOREIGN KEY (payment_entry_id)
    REFERENCES ledger_entries(id),
  FOREIGN KEY (charge_entry_id)
    REFERENCES ledger_entries(id),
  UNIQUE(payment_entry_id, charge_entry_id)
);

CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  action TEXT NOT NULL,
  actor TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  previous_hash TEXT,
  event_hash TEXT NOT NULL UNIQUE
);

CREATE INDEX IF NOT EXISTS idx_audit_entity
ON audit_events(entity_type, entity_id);

CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  organization_id TEXT NOT NULL,
  customer_id TEXT,
  document_type TEXT NOT NULL,
  filename TEXT NOT NULL,
  content_hash TEXT NOT NULL,
  storage_ref TEXT NOT NULL,
  created_at TEXT NOT NULL,
  metadata_json TEXT NOT NULL DEFAULT '{}',
  FOREIGN KEY (organization_id)
    REFERENCES organizations(id),
  FOREIGN KEY (customer_id)
    REFERENCES customers(id)
);

CREATE TABLE IF NOT EXISTS idempotency_keys (
  key TEXT PRIMARY KEY,
  operation TEXT NOT NULL,
  response_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS jobs (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  status TEXT NOT NULL,
  payload_json TEXT NOT NULL DEFAULT '{}',
  result_json TEXT,
  attempts INTEGER NOT NULL DEFAULT 0,
  available_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
__SCHEMA__

cat > "$APP/database/migrations/001_initial.sql" <<'__MIGRATION__'
INSERT OR IGNORE INTO schema_migrations
  (version, name, applied_at)
VALUES
  (1, 'initial', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
__MIGRATION__

cat > "$APP/database/db.ts" <<'__DB__'
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";

const dataDir =
  process.env.TABS_DATA_DIR ||
  join(process.cwd(), "data");

mkdirSync(dataDir, { recursive: true });

const dbPath =
  process.env.TABS_DB_PATH ||
  join(dataDir, "tabs.sqlite");

const globalState = globalThis as unknown as {
  tabsDb?: DatabaseSync;
};

export function getDb(): DatabaseSync {
  if (!globalState.tabsDb) {
    const db = new DatabaseSync(dbPath);

    db.exec(`
      PRAGMA foreign_keys = ON;
      PRAGMA journal_mode = WAL;
      PRAGMA synchronous = FULL;
      PRAGMA busy_timeout = 5000;
    `);

    globalState.tabsDb = db;
  }

  return globalState.tabsDb;
}

export function transaction<T>(fn: () => T): T {
  const db = getDb();

  db.exec("BEGIN IMMEDIATE");

  try {
    const result = fn();
    db.exec("COMMIT");
    return result;
  } catch (error) {
    try {
      db.exec("ROLLBACK");
    } catch {}
    throw error;
  }
}

export function databasePath() {
  return dbPath;
}
__DB__

cat > "$APP/database/migrate.ts" <<'__MIGRATE__'
import {
  readFileSync,
  readdirSync
} from "node:fs";
import { join } from "node:path";
import { getDb } from "./db";

export function migrate() {
  const db = getDb();

  db.exec(
    readFileSync(
      join(process.cwd(), "database", "schema.sql"),
      "utf8"
    )
  );

  const dir =
    join(process.cwd(), "database", "migrations");

  const files = readdirSync(dir)
    .filter((file) => file.endsWith(".sql"))
    .sort();

  for (const file of files) {
    const match = /^(\d+)_/.exec(file);
    if (!match) continue;

    const version = Number(match[1]);

    const exists = db.prepare(`
      SELECT 1
      FROM schema_migrations
      WHERE version = ?
      LIMIT 1
    `).get(version);

    if (!exists) {
      db.exec(
        readFileSync(
          join(dir, file),
          "utf8"
        )
      );
    }
  }
}
__MIGRATE__

cat > "$APP/types/domain.ts" <<'__DOMAIN__'
export type LedgerKind =
  | "charge"
  | "payment"
  | "credit"
  | "adjustment"
  | "reversal";

export type CustomerStatus =
  | "active"
  | "archived";

export interface Customer {
  id: string;
  organizationId: string;
  displayName: string;
  status: CustomerStatus;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface LedgerEntry {
  id: string;
  organizationId: string;
  customerId: string;
  kind: LedgerKind;
  amountCents: number;
  quantityText: string | null;
  item: string | null;
  location: string | null;
  description: string | null;
  effectiveAt: string;
  createdAt: string;
  source: string;
  sourceReference: string | null;
  metadata: Record<string, unknown>;
  reversedEntryId: string | null;
}
__DOMAIN__

cat > "$APP/core/security/ids.ts" <<'__IDS__'
import { randomUUID } from "node:crypto";

export function newId(prefix: string) {
  return `${prefix}_${randomUUID()}`;
}
__IDS__

cat > "$APP/core/serialization/json.ts" <<'__JSON__'
export function stableStringify(value: unknown): string {
  if (
    value === null ||
    typeof value !== "object"
  ) {
    return JSON.stringify(value);
  }

  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }

  const object =
    value as Record<string, unknown>;

  return `{${Object.keys(object)
    .sort()
    .map(
      (key) =>
        `${JSON.stringify(key)}:${stableStringify(object[key])}`
    )
    .join(",")}}`;
}
__JSON__

cat > "$APP/core/integrity/hash.ts" <<'__HASH__'
import { createHash } from "node:crypto";
import { stableStringify } from "../serialization/json";

export function sha256(value: unknown) {
  return createHash("sha256")
    .update(stableStringify(value))
    .digest("hex");
}
__HASH__

cat > "$APP/core/bootstrap.ts" <<'__BOOTSTRAP__'
import { migrate } from "@/database/migrate";
import { getDb } from "@/database/db";
import { newId } from "@/core/security/ids";

let ready = false;

export function bootstrap() {
  if (ready) return;

  migrate();

  const db = getDb();

  const existing = db.prepare(`
    SELECT id
    FROM organizations
    ORDER BY created_at
    LIMIT 1
  `).get() as { id: string } | undefined;

  if (!existing) {
    const id = newId("org");
    const now = new Date().toISOString();

    db.prepare(`
      INSERT INTO organizations
        (id, name, created_at, updated_at)
      VALUES (?, ?, ?, ?)
    `).run(
      id,
      "Default Organization",
      now,
      now
    );
  }

  ready = true;
}
__BOOTSTRAP__

cd "$APP"

node --input-type=module <<'__NODECHECK__'
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { DatabaseSync } from "node:sqlite";

mkdirSync(join(process.cwd(), "data"), {
  recursive: true
});

const db = new DatabaseSync(
  join(process.cwd(), "data", "tabs.sqlite")
);

db.exec(`
  PRAGMA journal_mode = WAL;
  PRAGMA synchronous = FULL;
  PRAGMA foreign_keys = ON;
`);

console.log("SQLite engine: PASS");
__NODECHECK__

printf '\n'
printf '\033[32m✓\033[0m STAGE 2 COMPLETE\n'
printf 'Run Stage 3:\n'
printf '  bash ~/tabs-stage3.sh\n'
