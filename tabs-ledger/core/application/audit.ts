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
