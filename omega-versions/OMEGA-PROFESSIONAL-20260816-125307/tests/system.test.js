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
