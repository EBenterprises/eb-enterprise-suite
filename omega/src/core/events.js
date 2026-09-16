const listeners = new Map()

export const on = (event, handler) => {
  const set = listeners.get(event) || new Set()
  set.add(handler)
  listeners.set(event, set)
  return () => set.delete(handler)
}

export const emit = async (event, payload = {}) => {
  const set = listeners.get(event) || []
  return Promise.all([...set].map(fn => fn(payload)))
}

export const events = () => [...listeners.keys()]

export const clearEvents = () => listeners.clear()
