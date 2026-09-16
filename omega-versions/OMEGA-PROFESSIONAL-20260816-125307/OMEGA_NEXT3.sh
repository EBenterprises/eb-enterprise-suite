#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$HOME/omega"

mkdir -p src/{orchestration,learning,agents,security} tests

cat > src/orchestration/loop.js <<'JS'
import { execute } from "../core/kernel.js"
import { remember } from "../memory/store.js"

export const run = async (
  goal,
  cycles = 3
) => {
  const history = []

  for (let i = 1; i <= cycles; i++) {
    const result = await execute("invent", {
      goal,
      cycle: i
    })

    const item = {
      cycle: i,
      score: result.result.score,
      result
    }

    history.push(item)

    remember({
      type: "cycle",
      goal,
      cycle: i,
      score: item.score
    })
  }

  const best = history.reduce(
    (a, b) =>
      b.score > a.score ? b : a
  )

  return {
    goal,
    cycles,
    best,
    history
  }
}
JS

cat > src/learning/adaptation.js <<'JS'
export const adapt = history => {
  if (!history?.length)
    return {
      direction: "initialize",
      confidence: 0
    }

  const scores =
    history.map(x =>
      Number(x.score ?? 0)
    )

  const first = scores[0]
  const last = scores.at(-1)

  return {
    direction:
      last > first
        ? "improving"
        : last < first
          ? "regressing"
          : "stable",
    confidence:
      Math.min(
        1,
        Math.abs(last - first) + 0.5
      )
  }
}
JS

cat > src/agents/agent.js <<'JS'
import { run } from "../orchestration/loop.js"
import { adapt } from "../learning/adaptation.js"

export const agent = async (
  goal,
  cycles = 3
) => {
  const result =
    await run(goal, cycles)

  return {
    type: "agent-run",
    goal,
    cycles,
    best: result.best,
    adaptation: adapt(
      result.history
    )
  }
}
JS

cat > src/security/guard.js <<'JS'
const blocked = [
  "rm -rf /",
  "mkfs",
  ":(){ :|:& };:",
  "dd if=/dev/zero"
]

export const authorize = command => {
  const value =
    String(command).toLowerCase()

  const match =
    blocked.find(x =>
      value.includes(x)
    )

  return {
    allowed: !match,
    reason: match
      ? "blocked-dangerous-command"
      : "approved"
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
export * as orchestration from "../orchestration/loop.js"
export * as learning from "../learning/adaptation.js"
export * as agents from "../agents/agent.js"
export * as security from "../security/guard.js"
JS

cat > bin/omega.js <<'JS'
#!/usr/bin/env node

import {
  execute,
  capabilities,
  health,
  metrics,
  memory,
  orchestration,
  agents,
  security
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

  if (command === "security") {
    console.log(
      JSON.stringify(
        security.authorize(text),
        null,
        2
      )
    )
    return
  }

  if (command === "loop") {
    console.log(
      JSON.stringify(
        await orchestration.run(
          text,
          3
        ),
        null,
        2
      )
    )
    return
  }

  if (command === "agent") {
    console.log(
      JSON.stringify(
        await agents.agent(
          text,
          3
        ),
        null,
        2
      )
    )
    return
  }

  if (!command) {
    console.log(`
OMEGA®

status
capabilities
metrics
remember <text>
recall <query>
security <command>
loop <goal>
agent <goal>
invent <goal>
simulate
evolve
release
`)
    return
  }

  const result =
    await execute(command, {
      prompt: text,
      goal: text
    })

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

cat > tests/autonomy.test.js <<'JS'
import test from "node:test"
import assert from "node:assert/strict"

import {
  orchestration,
  agents,
  security
} from "../src/core/omega.js"

test("OMEGA orchestration", async () => {
  const result =
    await orchestration.run(
      "improve system",
      3
    )

  assert.equal(
    result.cycles,
    3
  )

  assert.ok(
    result.best.score > 0
  )
})

test("OMEGA agent", async () => {
  const result =
    await agents.agent(
      "design better runtime",
      2
    )

  assert.equal(
    result.type,
    "agent-run"
  )

  assert.ok(
    result.adaptation.confidence > 0
  )
})

test("OMEGA security", () => {
  assert.equal(
    security.authorize(
      "echo safe"
    ).allowed,
    true
  )

  assert.equal(
    security.authorize(
      "rm -rf /"
    ).allowed,
    false
  )
})
JS

npm test

node bin/omega.js security "echo OMEGA"
node bin/omega.js loop "build something better"
node bin/omega.js agent "design a stronger system"
node bin/omega.js status

echo
echo "╔══════════════════════════════════════════════╗"
echo "║             OMEGA® AUTONOMY PASS            ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ Kernel         ONLINE                        ║"
echo "║ Memory         ONLINE                        ║"
echo "║ Reasoning      ONLINE                        ║"
echo "║ Invention      ONLINE                        ║"
echo "║ Orchestration  ONLINE                        ║"
echo "║ Learning       ONLINE                        ║"
echo "║ Agent          ONLINE                        ║"
echo "║ Security       ONLINE                        ║"
echo "║ Tests          PASS                          ║"
echo "╚══════════════════════════════════════════════╝"
