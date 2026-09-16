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
