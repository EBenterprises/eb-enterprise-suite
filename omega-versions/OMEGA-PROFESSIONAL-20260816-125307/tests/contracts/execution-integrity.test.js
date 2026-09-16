import test from "node:test"
import assert from "node:assert/strict"

import {
  execute,
  metrics
} from "../../src/core/omega.js"

test("OMEGA execution produces a structured result", async () => {
  const before =
    metrics.get("execution.total")

  const result =
    await execute(
      "simulate",
      {
        target: "integrity"
      }
    )

  assert.equal(
    result.capability,
    "simulate"
  )

  assert.equal(
    typeof result.duration,
    "number"
  )

  assert.equal(
    typeof result.timestamp,
    "string"
  )

  assert.ok(
    result.result !== undefined
  )

  assert.ok(
    metrics.get("execution.total") >
      before
  )
})

test("OMEGA unknown capability is deterministic", async () => {
  await assert.rejects(
    () =>
      execute(
        "__definitely_not_a_capability__"
      ),
    error => {
      assert.equal(
        error.code,
        "UNKNOWN_CAPABILITY"
      )

      assert.equal(
        error.details.name,
        "__definitely_not_a_capability__"
      )

      return true
    }
  )
})
