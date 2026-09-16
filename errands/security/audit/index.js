export function audit(action, actorId, metadata = {}) {
  return {
    id: crypto.randomUUID(),
    action,
    actorId,
    metadata,
    timestamp: new Date().toISOString()
  };
}
