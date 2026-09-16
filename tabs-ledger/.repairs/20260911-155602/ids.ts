import { randomUUID } from "node:crypto";

/**
 * Generate a globally unique application identifier.
 *
 * UUID v4 is suitable for local-first operation and future
 * replication because IDs do not depend on a central sequence.
 */
export function randomId(): string {
  return randomUUID();
}
