import test from "node:test"
import assert from "node:assert/strict"

import {
  flow,
  contracts,
  scheduler,
  plugins,
  observability
} from "../src/core/omega.js"

test("OMEGA flow", async () => {
  const x = await flow.flow("build")
  assert.equal(x.status, "complete")
  assert.ok(x.steps.length >= 5)
})

test("OMEGA contract", () => {
  const c = contracts.contract(
    "TEST",
    ["goal"]
  )

  assert.equal(
    c.validate({ goal: "x" }).valid,
    true
  )

  assert.equal(
    c.validate({}).valid,
    false
  )
})

test("OMEGA scheduler", () => {
  const x = scheduler.push({
    task: "test"
  })

  assert.equal(x.status, "queued")

  const y = scheduler.next()

  assert.equal(y.id, x.id)

  scheduler.complete(x.id)

  assert.equal(
    scheduler.all().find(
      z => z.id === x.id
    ).status,
    "complete"
  )
})

test("OMEGA plugins", () => {
  const x = plugins.install(
    "test-plugin",
    {
      version: "1.0.0",
      capabilities: ["test"]
    }
  )

  assert.equal(
    x.status,
    "installed"
  )
})

test("OMEGA observability", () => {
  const x = observability.probe()
  assert.equal(x.runtime, "healthy")
  assert.equal(x.kernel, "healthy")
})
