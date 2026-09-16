const registry = new Map()

export const register = (name, run, meta = {}) => {
  if (!name || typeof run !== "function")
    throw new TypeError("Invalid capability")
  registry.set(name, { name, run, meta })
  return registry.get(name)
}

export const get = name => registry.get(name)

export const list = () =>
  [...registry.values()].map(({ name, meta }) => ({ name, ...meta }))

export const clear = () => registry.clear()

export default registry
