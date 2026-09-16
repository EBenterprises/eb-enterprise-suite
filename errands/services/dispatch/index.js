export function createDispatch(requestId, runnerId) {
  return {
    id: crypto.randomUUID(),
    requestId,
    runnerId,
    status: "proposed",
    createdAt: new Date().toISOString()
  };
}
