const metrics = new Map()

export const increment = (name, amount = 1) => {
  metrics.set(
    name,
    (metrics.get(name) ?? 0) + amount
  )

  return metrics.get(name)
}

export const get = name =>
  metrics.get(name) ?? 0

export const snapshot = () =>
  Object.fromEntries(metrics)

export const reset = () =>
  metrics.clear()
