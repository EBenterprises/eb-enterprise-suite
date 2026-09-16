import fs from "node:fs"
import path from "node:path"

const root = path.resolve("data")
const file = path.join(root, "omega-state.json")

let state = {}

export const load = () => {
  fs.mkdirSync(root, { recursive: true })
  try {
    state = JSON.parse(fs.readFileSync(file, "utf8"))
  } catch {
    state = {}
  }
  return state
}

export const get = (key, fallback) =>
  key === undefined ? state : state[key] ?? fallback

export const set = (key, value) => {
  state[key] = value
  return value
}

export const update = patch => {
  state = { ...state, ...patch }
  return state
}

export const save = () => {
  fs.mkdirSync(root, { recursive: true })
  fs.writeFileSync(file, JSON.stringify(state, null, 2))
  return state
}

export const reset = () => {
  state = {}
  return state
}

load()
