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

/**
 * Canonical application database handle.
 *
 * All application services use this singleton.
 * The underlying connection is still managed by getDb().
 */
export const db = getDb();
