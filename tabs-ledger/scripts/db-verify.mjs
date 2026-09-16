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
