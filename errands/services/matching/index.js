export function scoreRunner(candidate = {}) {
  return (
    Number(candidate.distanceScore || 0) +
    Number(candidate.availabilityScore || 0) +
    Number(candidate.capabilityScore || 0)
  );
}
