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
