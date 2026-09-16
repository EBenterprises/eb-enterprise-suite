const queue = []

export const push = task => {
  const item = {
    id: queue.length + 1,
    created: new Date().toISOString(),
    status: "queued",
    ...task
  }

  queue.push(item)
  return item
}

export const next = () => {
  const item = queue.find(
    x => x.status === "queued"
  )

  if (item)
    item.status = "running"

  return item
}

export const complete = id => {
  const item = queue.find(
    x => x.id === id
  )

  if (item)
    item.status = "complete"

  return item
}

export const all = () => [...queue]
