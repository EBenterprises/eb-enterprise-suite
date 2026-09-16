import fs from "node:fs"
import path from "node:path"

const dir = path.resolve("data")
const file = path.join(dir, "omega-memory.json")

let memory = []

const persist = () => {
  fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(file, JSON.stringify(memory, null, 2))
}

export const load = () => {
  try {
    memory = JSON.parse(fs.readFileSync(file, "utf8"))
  } catch {
    memory = []
  }
  return memory
}

export const remember = (entry = {}) => {
  const item = {
    id: `${Date.now()}-${memory.length}`,
    timestamp: new Date().toISOString(),
    ...entry
  }
  memory.push(item)
  persist()
  return item
}

export const recall = (query = "") => {
  const q = String(query).toLowerCase()
  return memory.filter(x =>
    JSON.stringify(x).toLowerCase().includes(q)
  )
}

export const all = () => [...memory]

load()
