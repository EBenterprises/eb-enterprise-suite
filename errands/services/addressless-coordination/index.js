export function hasUsableLocation(location = {}) {
  return Boolean(
    location.address ||
    location.label ||
    location.instructions ||
    (
      location.latitude !== null &&
      location.longitude !== null
    )
  );
}
