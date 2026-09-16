import { randomUUID } from "node:crypto";

/**
 * Generate a globally unique application identifier.
 *
 * Optional prefix preserves the existing entity-oriented ID
 * convention while the UUID provides collision resistance.
 */
export function randomId(prefix?: string): string {
  const id = randomUUID();
  return prefix ? `${prefix}_${id}` : id;
}
