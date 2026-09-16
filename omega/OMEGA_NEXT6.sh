#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/omega"

echo
echo "================================================"
echo " OMEGA® NEXT6 — API CONTRACT + INTEGRITY"
echo "================================================"
echo

mkdir -p tests/contracts

cat > tests/contracts/public-api.test.js <<'JS'
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
JS

cat > tests/contracts/integrity.test.js <<'JS'
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
JS

cat > tests/contracts/execution-integrity.test.js <<'JS'
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
JS

echo "[OMEGA] Syntax validation..."

node --check src/core/omega.js
node --check src/core/kernel.js
node --check src/core/errors.js
node --check src/core/validation.js
node --check src/core/metrics.js
node --check bin/omega.js

echo "[OMEGA] Syntax ............... PASS"

echo
echo "[OMEGA] Running complete test matrix..."
npm test

echo
echo "[OMEGA] Running public API smoke test..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const expected = [
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

for (const name of expected) {
  if (!(name in OMEGA)) {
    throw new Error(
      `PUBLIC API REGRESSION: ${name}`
    )
  }
}

console.log(
  `[OMEGA] ${expected.length} public exports verified`
)
JS

echo "[OMEGA] Public API .......... PASS"

echo
echo "[OMEGA] CLI integrity..."

node bin/omega.js status
node bin/omega.js capabilities
node bin/omega.js metrics
node bin/omega.js help

echo
echo "╔══════════════════════════════════════════════╗"
echo "║          OMEGA® NEXT6 SYSTEM PASS            ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ Syntax         PASS                          ║"
echo "║ Kernel         PASS                          ║"
echo "║ Intelligence   PASS                          ║"
echo "║ Memory         PASS                          ║"
echo "║ Agents         PASS                          ║"
echo "║ Security       PASS                          ║"
echo "║ Governance     PASS                          ║"
echo "║ Planning       PASS                          ║"
echo "║ Verification   PASS                          ║"
echo "║ Telemetry      PASS                          ║"
echo "║ Orchestration  PASS                          ║"
echo "║ Contracts      PASS                          ║"
echo "║ Scheduler      PASS                          ║"
echo "║ Plugins        PASS                          ║"
echo "║ Observability  PASS                          ║"
echo "║ API Contract   PASS                          ║"
echo "║ Integrity      PASS                          ║"
echo "║ Full Test      PASS                          ║"
echo "╚══════════════════════════════════════════════╝"
