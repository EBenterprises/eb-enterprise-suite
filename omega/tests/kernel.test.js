import test from "node:test"
import assert from "node:assert/strict"

import {
  execute,
  capabilities,
  health
} from "../src/core/omega.js"

test("OMEGA identity", () => {
  assert.equal(health().name, "OMEGA")
})

test("OMEGA capabilities", () => {
  const names = capabilities().map(x => x.name)
  assert.deepEqual(
    names.sort(),
    ["evolve", "invent", "release", "simulate"].sort()
  )
})

test("OMEGA invention execution", async () => {
  const result = await execute("invent", {
    goal: "build something better"
  })

  assert.equal(result.capability, "invent")
  assert.equal(result.result.type, "invention")
})

test("OMEGA simulation execution", async () => {
  const result = await execute("simulate", {
    target: "system"
  })

  assert.equal(result.result.status, "complete")
})

test("OMEGA evolution execution", async () => {
  const result = await execute("evolve", {
    generation: 4
  })

  assert.equal(result.result.generation, 5)
})
