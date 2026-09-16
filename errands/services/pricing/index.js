export function calculatePrice({
  base = 0,
  distance = 0,
  complexity = 0
} = {}) {
  return Math.max(
    0,
    Number(base) +
    Number(distance) +
    Number(complexity)
  );
}
