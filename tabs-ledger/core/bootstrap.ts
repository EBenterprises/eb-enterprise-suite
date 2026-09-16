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
