export const adapt = history => {
  if (!history?.length)
    return {
      direction: "initialize",
      confidence: 0
    }

  const scores =
    history.map(x =>
      Number(x.score ?? 0)
    )

  const first = scores[0]
  const last = scores.at(-1)

  return {
    direction:
      last > first
        ? "improving"
        : last < first
          ? "regressing"
          : "stable",
    confidence:
      Math.min(
        1,
        Math.abs(last - first) + 0.5
      )
  }
}
