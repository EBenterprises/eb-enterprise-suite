import { createHash } from "node:crypto";
import { db } from "../../database/db";

function canonical(value: unknown): string {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }

  if (Array.isArray(value)) {
    return `[${value.map(canonical).join(",")}]`;
  }

  const object = value as Record<string, unknown>;

  return `{${Object.keys(object)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${canonical(object[key])}`)
    .join(",")}}`;
}

function hash(value: unknown): string {
  return createHash("sha256")
    .update(canonical(value))
    .digest("hex");
}

export function verifyAuditChain() {
  const rows = db.prepare(`
    SELECT
      id,
      event_type,
      entity_type,
      entity_id,
      payload_json,
      previous_hash,
      event_hash,
      created_at
    FROM audit_events
    ORDER BY created_at ASC, id ASC
  `).all() as Array<{
    id: string;
    event_type: string;
    entity_type: string;
    entity_id: string;
    payload_json: string;
    previous_hash: string | null;
    event_hash: string;
    created_at: string;
  }>;

  const issues: Array<{
    id: string;
    type: string;
    message: string;
  }> = [];

  let previousHash: string | null = null;

  for (const row of rows) {
    if ((row.previous_hash || null) !== previousHash) {
      issues.push({
        id: row.id,
        type: "previous_hash_mismatch",
        message: "Audit event does not reference the preceding hash.",
      });
    }

    const expectedHash = hash({
      id: row.id,
      event_type: row.event_type,
      entity_type: row.entity_type,
      entity_id: row.entity_id,
      payload_json: row.payload_json,
      previous_hash: row.previous_hash,
      created_at: row.created_at,
    });

    if (expectedHash !== row.event_hash) {
      issues.push({
        id: row.id,
        type: "event_hash_mismatch",
        message: "Stored audit hash does not match event contents.",
      });
    }

    previousHash = row.event_hash;
  }

  return {
    ok: issues.length === 0,
    checked_at: new Date().toISOString(),
    events_checked: rows.length,
    issues,
    head_hash: previousHash,
  };
}
