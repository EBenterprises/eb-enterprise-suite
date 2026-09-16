#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/omega"

mkdir -p \
  src/core \
  src/intelligence \
  src/engines \
  src/runtime \
  tests \
  data \
  versions \
  build \
  dist

# ============================================================
# OMEGA® CORE — COMPACT EXECUTION KERNEL
# ============================================================

cat > src/core/registry.js <<'EOF'
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
EOF

cat > src/core/events.js <<'EOF'
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
EOF

cat > src/core/state.js <<'EOF'
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
EOF

cat > src/core/kernel.js <<'EOF'
import { get, list } from "./registry.js"
import { emit } from "./events.js"
import * as state from "./state.js"

export const execute = async (name, input = {}, context = {}) => {
  const capability = get(name)

  if (!capability)
    throw new Error(`Unknown capability: ${name}`)

  const started = Date.now()

  await emit("before:execute", { name, input, context })

  const result = await capability.run(input, {
    ...context,
    state,
    execute
  })

  const output = {
    capability: name,
    result,
    duration: Date.now() - started,
    timestamp: new Date().toISOString()
  }

  await emit("after:execute", output)

  state.set("lastExecution", output)
  state.save()

  return output
}

export const capabilities = () => list()

export const health = () => ({
  name: "OMEGA",
  status: "operational",
  capabilities: list().length,
  timestamp: new Date().toISOString()
})
EOF

# ============================================================
# OMEGA® INTELLIGENCE
# ============================================================

cat > src/intelligence/planner.js <<'EOF'
export const plan = (goal, context = {}) => ({
  goal,
  context,
  steps: [
    { type: "observe", goal },
    { type: "analyze", goal },
    { type: "generate", goal },
    { type: "evaluate", goal },
    { type: "optimize", goal }
  ]
})
EOF

cat > src/intelligence/evaluator.js <<'EOF'
export const evaluate = (value, criteria = {}) => {
  const checks = Object.entries(criteria)
  const passed = checks.filter(([key, expected]) => value?.[key] === expected)
  return {
    score: checks.length ? passed.length / checks.length : 1,
    passed: passed.length,
    total: checks.length,
    valid: passed.length === checks.length
  }
}
EOF

cat > src/intelligence/optimizer.js <<'EOF'
export const optimize = (value, transforms = []) =>
  transforms.reduce(
    (current, transform) => transform(current),
    value
  )
EOF

# ============================================================
# OMEGA® ENGINES
# ============================================================

cat > src/engines/invention.js <<'EOF'
import { plan } from "../intelligence/planner.js"

export const invent = async (input = {}) => ({
  type: "invention",
  goal: input.goal ?? input.prompt ?? String(input),
  plan: plan(input.goal ?? input.prompt ?? String(input))
})
EOF

cat > src/engines/simulation.js <<'EOF'
export const simulate = async (input = {}) => ({
  type: "simulation",
  input,
  status: "complete",
  outcome: "simulated"
})
EOF

cat > src/engines/evolution.js <<'EOF'
export const evolve = async (input = {}) => ({
  type: "evolution",
  input,
  generation: Number(input.generation ?? 1) + 1,
  status: "ready"
})
EOF

cat > src/engines/release.js <<'EOF'
export const release = async (input = {}) => ({
  type: "release",
  version: input.version ?? "next",
  status: "prepared"
})
EOF

# ============================================================
# OMEGA® RUNTIME
# ============================================================

cat > src/runtime/bootstrap.js <<'EOF'
import { register } from "../core/registry.js"
import { invent } from "../engines/invention.js"
import { simulate } from "../engines/simulation.js"
import { evolve } from "../engines/evolution.js"
import { release } from "../engines/release.js"

export const bootstrap = () => {
  register("invent", invent, { category: "intelligence" })
  register("simulate", simulate, { category: "analysis" })
  register("evolve", evolve, { category: "evolution" })
  register("release", release, { category: "deployment" })
}
EOF

# ============================================================
# OMEGA® PUBLIC API
# ============================================================

cat > src/core/omega.js <<'EOF'
import { bootstrap } from "../runtime/bootstrap.js"
import { execute, capabilities, health } from "./kernel.js"

bootstrap()

export { execute, capabilities, health }
export * as registry from "./registry.js"
export * as events from "./events.js"
export * as state from "./state.js"
EOF

# ============================================================
# OMEGA® CLI
# ============================================================

cat > bin/omega.js <<'EOF'
#!/usr/bin/env node

import { execute, capabilities, health } from "../src/core/omega.js"

const [command, ...args] = process.argv.slice(2)

const input = {
  prompt: args.join(" "),
  goal: args.join(" ")
}

const main = async () => {
  if (command === "status") {
    console.log(JSON.stringify(health(), null, 2))
    return
  }

  if (command === "capabilities" || command === "list") {
    console.log(JSON.stringify(capabilities(), null, 2))
    return
  }

  if (!command) {
    console.log("OMEGA®")
    console.log("status | capabilities | invent | simulate | evolve | release")
    return
  }

  const result = await execute(command, input)
  console.log(JSON.stringify(result, null, 2))
}

main().catch(error => {
  console.error(`[OMEGA ERROR] ${error.message}`)
  process.exitCode = 1
})
EOF

chmod +x bin/omega.js

# ============================================================
# OMEGA® TESTS
# ============================================================

cat > tests/kernel.test.js <<'EOF'
import test from "node:test"
import assert from "node:assert/strict"

import {
  execute,
  capabilities,
  health
} from "../src/core/omega.js"

test("OMEGA identity", () => {
  assert.equal(health().name, "OMEGA")
})

test("OMEGA capabilities", () => {
  const names = capabilities().map(x => x.name)
  assert.deepEqual(
    names.sort(),
    ["evolve", "invent", "release", "simulate"].sort()
  )
})

test("OMEGA invention execution", async () => {
  const result = await execute("invent", {
    goal: "build something better"
  })

  assert.equal(result.capability, "invent")
  assert.equal(result.result.type, "invention")
})

test("OMEGA simulation execution", async () => {
  const result = await execute("simulate", {
    target: "system"
  })

  assert.equal(result.result.status, "complete")
})

test("OMEGA evolution execution", async () => {
  const result = await execute("evolve", {
    generation: 4
  })

  assert.equal(result.result.generation, 5)
})
EOF

# ============================================================
# FIX EXISTING ROOT TEST
# ============================================================

if [ -f tests/omega.test.js ]; then
  sed -i 's/"TEST"/"OMEGA"/g' tests/omega.test.js
  sed -i "s/'TEST'/'OMEGA'/g" tests/omega.test.js
fi

# ============================================================
# PACKAGE COMMANDS
# ============================================================

node -e '
const fs=require("fs")
const p=JSON.parse(fs.readFileSync("package.json","utf8"))
p.scripts ??= {}
p.scripts.test="node --test"
p.scripts.start="node bin/omega.js status"
p.scripts.status="node bin/omega.js status"
p.scripts.capabilities="node bin/omega.js capabilities"
p.scripts.invent="node bin/omega.js invent"
p.scripts.simulate="node bin/omega.js simulate"
p.scripts.evolve="node bin/omega.js evolve"
p.scripts.release="node bin/omega.js release"
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n")
'

# ============================================================
# VALIDATION
# ============================================================

echo
echo "================ OMEGA® VALIDATION ================"
echo

npm test

echo
node bin/omega.js status

echo
node bin/omega.js capabilities

echo
node bin/omega.js invent "build something better"

echo
node bin/omega.js simulate

echo
node bin/omega.js evolve

echo
node bin/omega.js release

echo
echo "===================================================="
echo " OMEGA® KERNEL ONLINE"
echo "===================================================="
echo
echo "Capabilities:"
echo "  omega status"
echo "  omega capabilities"
echo "  omega invent \"goal\""
echo "  omega simulate"
echo "  omega evolve"
echo "  omega release"
echo
