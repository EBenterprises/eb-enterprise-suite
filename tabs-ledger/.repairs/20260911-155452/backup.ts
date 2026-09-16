import fs from "node:fs";
import path from "node:path";
import { db } from "@/database/db";
import { DatabaseSync } from "node:sqlite";

const backupDirectory = path.resolve(process.cwd(), "backups");

function ensureDirectory() {
  fs.mkdirSync(backupDirectory, {
    recursive: true,
  });
}

function sqlString(value: string) {
  return `'${value.replaceAll("'", "''")}'`;
}

export function createVerifiedBackup() {
  ensureDirectory();

  const stamp = new Date()
    .toISOString()
    .replaceAll(":", "-")
    .replaceAll(".", "-");

  const destination = path.join(
    backupDirectory,
    `tabs-ledger-${stamp}.sqlite`
  );

  /*
   * VACUUM INTO creates a consistent SQLite snapshot.
   * It is safer than copying a live WAL database file directly.
   */
  db.exec(`VACUUM INTO ${sqlString(destination)}`);

  const stat = fs.statSync(destination);

  if (stat.size <= 0) {
    throw new Error("Backup was created but is empty.");
  }

  /*
   * Verify the backup can be opened and queried before reporting success.
   */
  const verify = new DatabaseSync(destination, { readOnly: true });

  try {
    const result = verify
      .prepare(`
        SELECT
          (SELECT COUNT(*) FROM customers) AS customers,
          (SELECT COUNT(*) FROM ledger_entries) AS ledger_entries,
          (SELECT COUNT(*) FROM payment_allocations) AS allocations
      `)
      .get() as {
        customers: number;
        ledger_entries: number;
        allocations: number;
      };

    return {
      ok: true,
      path: destination,
      bytes: stat.size,
      counts: result,
      created_at: new Date().toISOString(),
    };
  } finally {
    verify.close();
  }
}

export function listBackups() {
  ensureDirectory();

  return fs
    .readdirSync(backupDirectory)
    .filter((name) => name.endsWith(".sqlite"))
    .map((name) => {
      const full = path.join(backupDirectory, name);
      const stat = fs.statSync(full);

      return {
        name,
        path: full,
        bytes: stat.size,
        modified_at: stat.mtime.toISOString(),
      };
    })
    .sort((a, b) =>
      b.modified_at.localeCompare(a.modified_at)
    );
}
