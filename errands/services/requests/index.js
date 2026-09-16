export function validateRequest(request = {}) {
  const errors = [];

  if (!request.title) errors.push("title");
  if (!request.pickup) errors.push("pickup");
  if (!request.dropoff) errors.push("dropoff");

  return {
    valid: errors.length === 0,
    errors
  };
}
