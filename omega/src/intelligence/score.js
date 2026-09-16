export const score = candidate => {
  const values = [
    Number(candidate.novelty ?? 0),
    Number(candidate.utility ?? 0),
    Number(candidate.resilience ?? 0),
    Number(candidate.feasibility ?? 0)
  ]

  return values.reduce((a,b) => a + b, 0) / values.length
}
