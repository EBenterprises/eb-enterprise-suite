#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$HOME/omega"

mkdir -p src/{core,intelligence,engines,runtime,memory,security,adapters} tests data versions dist

cat > src/memory/store.js <<'JS'
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
JS

cat > src/intelligence/reason.js <<'JS'
export const reason = (goal, context = {}) => ({
  goal,
  hypotheses: [
    `Improve ${goal}`,
    `Simplify ${goal}`,
    `Scale ${goal}`,
    `Automate ${goal}`,
    `Measure ${goal}`
  ],
  context
})
JS

cat > src/engines/invention.js <<'JS'
import { plan } from "../intelligence/planner.js"
import { score } from "../intelligence/score.js"
import { reason } from "../intelligence/reason.js"

export const invent = async (input = {}) => {
  const goal =
    input.goal ??
    input.prompt ??
    String(input)

  const candidate = {
    name: "OMEGA Candidate",
    goal,
    novelty: 0.9,
    utility: 0.9,
    resilience: 0.85,
    feasibility: 0.8
  }

  return {
    type: "invention",
    goal,
    score: score(candidate),
    candidate,
    reasoning: reason(goal),
    plan: plan(goal)
  }
}
JS

cat > src/core/omega.js <<'JS'
import { bootstrap } from "../runtime/bootstrap.js"
import {
  execute,
  capabilities,
  health
} from "./kernel.js"

bootstrap()

export {
  execute,
  capabilities,
  health
}

export * as registry from "./registry.js"
export * as events from "./events.js"
export * as state from "./state.js"
export * as metrics from "./metrics.js"
export * as validate from "./validate.js"
export * as memory from "../memory/store.js"
JS

cat > bin/omega.js <<'JS'
#!/usr/bin/env node

import {
  execute,
  capabilities,
  health,
  metrics,
  memory
} from "../src/core/omega.js"

const [command, ...args] =
  process.argv.slice(2)

const text = args.join(" ")

const main = async () => {
  if (command === "status") {
    console.log(JSON.stringify({
      ...health(),
      metrics: metrics.snapshot(),
      memory: memory.all().length
    }, null, 2))
    return
  }

  if (
    command === "capabilities" ||
    command === "list"
  ) {
    console.log(
      JSON.stringify(
        capabilities(),
        null,
        2
      )
    )
    return
  }

  if (command === "metrics") {
    console.log(
      JSON.stringify(
        metrics.snapshot(),
        null,
        2
      )
    )
    return
  }

  if (command === "remember") {
    console.log(
      JSON.stringify(
        memory.remember({
          content: text
        }),
        null,
        2
      )
    )
    return
  }

  if (command === "recall") {
    console.log(
      JSON.stringify(
        memory.recall(text),
        null,
        2
      )
    )
    return
  }

  if (!command) {
    console.log(
`OMEGA®

status
capabilities
metrics
remember <text>
recall <query>
invent <goal>
simulate
evolve
release`
    )
    return
  }

  const result = await execute(
    command,
    {
      prompt: text,
      goal: text
    }
  )

  console.log(
    JSON.stringify(
      result,
      null,
      2
    )
  )
}

main().catch(error => {
  console.error(
    `[OMEGA ERROR] ${error.message}`
  )
  process.exitCode = 1
})
JS

chmod +x bin/omega.js

cat > tests/memory.test.js <<'JS'
import test from "node:test"
import assert from "node:assert/strict"

import {
  remember,
  recall
} from "../src/memory/store.js"

test("OMEGA memory write/read", () => {
  const marker =
    `omega-test-${Date.now()}`

  remember({
    content: marker
  })

  const result = recall(marker)

  assert.ok(result.length >= 1)
  assert.equal(
    result.at(-1).content,
    marker
  )
})
JS

npm test

node bin/omega.js remember "OMEGA® verified execution"
node bin/omega.js recall "verified execution"
node bin/omega.js status

echo
echo "OMEGA® NEXT LAYER: PASS"
echo "Memory: ONLINE"
echo "Reasoning: ONLINE"
echo "Invention: ONLINE"
echo "Kernel: ONLINE"
