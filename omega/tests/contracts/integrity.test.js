import test from "node:test"
import assert from "node:assert/strict"

import * as OMEGA from "../../src/core/omega.js"

test("OMEGA rejects invalid required input", () => {
  assert.throws(
    () => OMEGA.required("", "goal"),
    error => {
      assert.equal(
        error.code,
        "INVALID_INPUT"
      )
      return true
    }
  )
})

test("OMEGA validates objects", () => {
  assert.deepEqual(
    OMEGA.object({
      valid: true
    }, "payload"),
    {
      valid: true
    }
  )

  assert.throws(
    () => OMEGA.object(null, "payload"),
    error => {
      assert.equal(
        error.code,
        "INVALID_OBJECT"
      )
      return true
    }
  )
})

test("OMEGA scheduler lifecycle", () => {
  const item = OMEGA.scheduler.push({
    task: "integrity-check"
  })

  assert.equal(
    item.status,
    "queued"
  )

  const running =
    OMEGA.scheduler.next()

  assert.equal(
    running.id,
    item.id
  )

  assert.equal(
    running.status,
    "running"
  )

  const completed =
    OMEGA.scheduler.complete(item.id)

  assert.equal(
    completed.status,
    "complete"
  )
})

test("OMEGA plugin lifecycle", () => {
  const name =
    `integrity-plugin-${Date.now()}`

  const installed =
    OMEGA.plugins.install(name, {
      version: "1.0.0",
      capabilities: [
        "integrity"
      ]
    })

  assert.equal(
    installed.name,
    name
  )

  assert.equal(
    installed.status,
    "installed"
  )

  assert.deepEqual(
    installed.capabilities,
    ["integrity"]
  )

  assert.equal(
    OMEGA.plugins.uninstall(name),
    true
  )
})

test("OMEGA observability remains healthy", () => {
  const health =
    OMEGA.observability.probe()

  assert.equal(
    health.runtime,
    "healthy"
  )

  assert.equal(
    health.kernel,
    "healthy"
  )

  assert.equal(
    health.memory,
    "healthy"
  )

  assert.equal(
    health.intelligence,
    "healthy"
  )

  assert.equal(
    health.security,
    "healthy"
  )
})
