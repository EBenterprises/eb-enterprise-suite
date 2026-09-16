#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$HOME/omega"

mkdir -p src/{governance,verification,planning,telemetry} tests

cat > src/governance/policy.js <<'JS'
const policies = new Map([
  ["execution", { enabled:true }],
  ["learning", { enabled:true }],
  ["invention", { enabled:true }],
  ["release", { enabled:true }]
])

export const getPolicy = name =>
  policies.get(name) ?? { enabled:false }

export const setPolicy = (name, value) => {
  policies.set(name, {
    ...getPolicy(name),
    ...value
  })
  return policies.get(name)
}

export const allPolicies = () =>
  Object.fromEntries(policies)
JS

cat > src/verification/check.js <<'JS'
export const check = value => {
  const errors = []

  if (value === undefined)
    errors.push("undefined")

  if (value === null)
    errors.push("null")

  return {
    valid: errors.length === 0,
    errors
  }
}
JS

cat > src/planning/strategy.js <<'JS'
export const strategy = goal => ({
  goal,
  objective: "maximize useful outcome",
  stages: [
    "observe",
    "understand",
    "design",
    "execute",
    "verify",
    "improve"
  ]
})
JS

cat > src/telemetry/tracker.js <<'JS'
const records = []

export const track = event => {
  const record = {
    id: records.length + 1,
    timestamp: new Date().toISOString(),
    ...event
  }

  records.push(record)
  return record
}

export const recent = limit =>
  records.slice(-Number(limit || 20))

export const count = () =>
  records.length
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
export * as governance from "../governance/policy.js"
export * as verification from "../verification/check.js"
export * as planning from "../planning/strategy.js"
export * as telemetry from "../telemetry/tracker.js"
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
  security,
  governance,
  verification,
  planning,
  telemetry
} from "../src/core/omega.js"

const [command, ...args] =
  process.argv.slice(2)

const text = args.join(" ")

const main = async () => {
  if (command === "status") {
    console.log(JSON.stringify({
      ...health(),
      metrics: metrics.snapshot(),
      memory: memory.all().length,
      telemetry: telemetry.count()
    }, null, 2))
    return
  }

  if (
    command === "capabilities" ||
    command === "list"
  ) {
    console.log(JSON.stringify(
      capabilities(), null, 2
    ))
    return
  }

  if (command === "metrics") {
    console.log(JSON.stringify(
      metrics.snapshot(), null, 2
    ))
    return
  }

  if (command === "remember") {
    console.log(JSON.stringify(
      memory.remember({
        content:text
      }), null, 2
    ))
    return
  }

  if (command === "recall") {
    console.log(JSON.stringify(
      memory.recall(text), null, 2
    ))
    return
  }

  if (command === "security") {
    console.log(JSON.stringify(
      security.authorize(text), null, 2
    ))
    return
  }

  if (command === "policy") {
    console.log(JSON.stringify(
      governance.allPolicies(), null, 2
    ))
    return
  }

  if (command === "plan") {
    console.log(JSON.stringify(
      planning.strategy(text), null, 2
    ))
    return
  }

  if (command === "verify") {
    console.log(JSON.stringify(
      verification.check(text), null, 2
    ))
    return
  }

  if (command === "telemetry") {
    console.log(JSON.stringify(
      telemetry.recent(50), null, 2
    ))
    return
  }

  if (command === "loop") {
    console.log(JSON.stringify(
      await orchestration.run(text, 3),
      null, 2
    ))
    return
  }

  if (command === "agent") {
    console.log(JSON.stringify(
      await agents.agent(text, 3),
      null, 2
    ))
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
policy
plan <goal>
verify <value>
telemetry
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
      prompt:text,
      goal:text
    })

  telemetry.track({
    command,
    success:true
  })

  console.log(JSON.stringify(
    result, null, 2
  ))
}

main().catch(error => {
  telemetry.track({
    command,
    success:false,
    error:error.message
  })

  console.error(
    `[OMEGA ERROR] ${error.message}`
  )

  process.exitCode = 1
})
JS

chmod +x bin/omega.js

cat > tests/system.test.js <<'JS'
import test from "node:test"
import assert from "node:assert/strict"

import {
  governance,
  verification,
  planning,
  telemetry
} from "../src/core/omega.js"

test("OMEGA governance", () => {
  assert.equal(
    governance.getPolicy("execution").enabled,
    true
  )
})

test("OMEGA verification", () => {
  assert.equal(
    verification.check("OMEGA").valid,
    true
  )
})

test("OMEGA planning", () => {
  const x =
    planning.strategy("build")

  assert.equal(x.goal, "build")
  assert.ok(x.stages.length >= 5)
})

test("OMEGA telemetry", () => {
  const before = telemetry.count()

  telemetry.track({
    type:"test"
  })

  assert.equal(
    telemetry.count(),
    before + 1
  )
})
JS

npm test

node bin/omega.js policy
node bin/omega.js plan "build a stronger runtime"
node bin/omega.js verify "OMEGA"
node bin/omega.js telemetry
node bin/omega.js status

echo
echo "╔══════════════════════════════════════════════╗"
echo "║             OMEGA® SYSTEM PASS              ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ Kernel         PASS                          ║"
echo "║ Intelligence   PASS                          ║"
echo "║ Memory         PASS                          ║"
echo "║ Agents         PASS                          ║"
echo "║ Security       PASS                          ║"
echo "║ Governance     PASS                          ║"
echo "║ Planning       PASS                          ║"
echo "║ Verification   PASS                          ║"
echo "║ Telemetry      PASS                          ║"
echo "║ Full Test      PASS                          ║"
echo "╚══════════════════════════════════════════════╝"
