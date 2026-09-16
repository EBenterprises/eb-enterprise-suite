import test from "node:test"
import assert from "node:assert/strict"

import {
  execute,
  health,
  capabilities
} from "../src/core/omega.js"

test("OMEGA health", () => {
  assert.equal(
    health().status,
    "operational"
  )
})

test("OMEGA capability surface", () => {
  assert.equal(
    capabilities().length,
    4
  )
})

test("OMEGA invention scoring", async () => {
  const x =
    await execute("invent", {
      goal: "build something better"
    })

  assert.equal(
    x.result.type,
    "invention"
  )

  assert.ok(
    x.result.score > 0
  )

  assert.ok(
    x.result.plan.steps.length >= 5
  )
})
