import test from "node:test"
import assert from "node:assert/strict"

import * as OMEGA from "../../src/core/omega.js"

const REQUIRED_EXPORTS = [
  "execute",
  "capabilities",
  "health",
  "registry",
  "events",
  "state",
  "metrics",
  "memory",
  "orchestration",
  "learning",
  "agents",
  "security",
  "governance",
  "verification",
  "planning",
  "telemetry",
  "flow",
  "contracts",
  "scheduler",
  "plugins",
  "observability",
  "OmegaError",
  "fail",
  "required",
  "object"
]

test("OMEGA public API contract", () => {
  const missing = REQUIRED_EXPORTS.filter(
    name => !(name in OMEGA)
  )

  assert.deepEqual(
    missing,
    [],
    `Missing public exports: ${missing.join(", ")}`
  )
})

test("OMEGA public API exports are callable or objects", () => {
  for (const name of REQUIRED_EXPORTS) {
    const value = OMEGA[name]

    assert.notEqual(
      value,
      undefined,
      `Export ${name} is undefined`
    )
  }
})

test("OMEGA health contract", () => {
  const result = OMEGA.health()

  assert.equal(result.name, "OMEGA")
  assert.equal(result.status, "operational")
  assert.equal(
    typeof result.capabilities,
    "number"
  )
  assert.ok(result.capabilities >= 0)
  assert.equal(
    typeof result.timestamp,
    "string"
  )
})

test("OMEGA capability surface is stable", () => {
  const capabilities = OMEGA.capabilities()

  assert.ok(Array.isArray(capabilities))

  for (const capability of capabilities) {
    assert.ok(capability)
  }
})

test("OMEGA metrics surface is stable", () => {
  assert.equal(
    typeof OMEGA.metrics.snapshot,
    "function"
  )

  assert.equal(
    typeof OMEGA.metrics.increment,
    "function"
  )

  assert.equal(
    typeof OMEGA.metrics.get,
    "function"
  )

  assert.equal(
    typeof OMEGA.metrics.reset,
    "function"
  )

  assert.equal(
    typeof OMEGA.metrics.snapshot(),
    "object"
  )
})
