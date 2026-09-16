export function parseOmega(source) {
  const root = {}
  const stack = [[-1, root]]

  for (const raw of String(source).split(/\r?\n/)) {
    const line = raw.replace(/#.*$/, "")
    if (!line.trim()) continue

    const indent = line.match(/^\s*/)[0].length
    const text = line.trim()

    while (stack.length > 1 && indent <= stack.at(-1)[0])
      stack.pop()

    const parent = stack.at(-1)[1]

    const rootDecl = text.match(/^omega\s+"([^"]+)"\s*$/)
    if (rootDecl) {
      root.omega = rootDecl[1]
      root.name = rootDecl[1]
      continue
    }

    const block = text.match(
      /^([A-Za-z_][\w-]*)(?:\s+"([^"]+)")?\s*\{$/
    )

    if (block) {
      const key = block[1]
      const object = {}

      if (block[2])
        object.name = block[2]

      parent[key] = object
      stack.push([indent, object])
      continue
    }

    const pair = text.match(
      /^([A-Za-z_][\w-]*)\s+(.+)$/
    )

    if (!pair) continue

    const key = pair[1]
    let value = pair[2].trim()

    if (value.startsWith('"') && value.endsWith('"'))
      value = value.slice(1, -1)
    else if (value === "true")
      value = true
    else if (value === "false")
      value = false
    else if (value === "null")
      value = null
    else if (/^-?\d+(\.\d+)?$/.test(value))
      value = Number(value)

    parent[key] = value
  }

  root.name ??= "OMEGA"
  root.version ??= root.system?.version ?? "1.0.0"

  return root
}
