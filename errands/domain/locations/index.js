export const LOCATION_TYPES = Object.freeze([
  "address",
  "business",
  "landmark",
  "entrance",
  "meeting_point",
  "coordinates",
  "shared_location",
  "live_location",
  "custom"
]);

export function createLocation(input = {}) {
  return {
    id: crypto.randomUUID(),
    type: input.type || "custom",
    label: input.label || "",
    address: input.address || null,
    latitude: input.latitude ?? null,
    longitude: input.longitude ?? null,
    instructions: input.instructions || "",
    createdAt: new Date().toISOString()
  };
}
