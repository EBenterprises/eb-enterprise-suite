export function trackingEvent(input = {}) {
  return {
    id: crypto.randomUUID(),
    errandId: input.errandId || null,
    latitude: input.latitude ?? null,
    longitude: input.longitude ?? null,
    timestamp: new Date().toISOString()
  };
}
