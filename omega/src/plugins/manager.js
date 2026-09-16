const plugins = new Map()

export const install = (
  name,
  plugin = {}
) => {
  if (!name)
    throw new Error("Plugin name required")

  plugins.set(name, {
    name,
    version: plugin.version ?? "1.0.0",
    status: "installed",
    capabilities:
      plugin.capabilities ?? []
  })

  return plugins.get(name)
}

export const uninstall = name =>
  plugins.delete(name)

export const list = () =>
  [...plugins.values()]
