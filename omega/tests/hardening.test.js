import test from "node:test"
import assert from "node:assert/strict"

import {
  execute,
  health,
  metrics,
  required
} from "../src/core/omega.js"

test(
  "OMEGA rejects unknown capability",
  async () => {
    await assert.rejects(
      () => execute("does-not-exist"),
      error =>
        error.code === "UNKNOWN_CAPABILITY"
    )
  }
)

test(
  "OMEGA validates required values",
  () => {
    assert.throws(
      () => required("", "goal"),
      error =>
        error.code === "INVALID_INPUT"
    )
  }
)

test(
  "OMEGA records execution metrics",
  async () => {
    await execute(
      "simulate",
      { target: "test" }
    )

    assert.ok(
      metrics.get("execution.total") >= 1
    )

    assert.ok(
      metrics.get("execution.simulate") >= 1
    )
  }
)

test(
  "OMEGA remains operational",
  () => {
    assert.equal(
      health().status,
      "operational"
    )
  }
)
