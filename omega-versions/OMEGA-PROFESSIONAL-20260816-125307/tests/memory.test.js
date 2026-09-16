import test from "node:test"
import assert from "node:assert/strict"

import {
  remember,
  recall
} from "../src/memory/store.js"

test("OMEGA memory write/read", () => {
  const marker =
    `omega-test-${Date.now()}`

  remember({
    content: marker
  })

  const result = recall(marker)

  assert.ok(result.length >= 1)
  assert.equal(
    result.at(-1).content,
    marker
  )
})
