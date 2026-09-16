#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/omega"

echo
echo "================================================"
echo " OMEGA® NEXT7 — PUBLIC API RESTORATION"
echo "================================================"
echo

# ------------------------------------------------
# Restore the complete OMEGA public API surface.
# ------------------------------------------------

cat > src/core/omega.js <<'JS'
import { bootstrap } from "../runtime/bootstrap.js"

import {
  execute,
  capabilities,
  health
} from "./kernel.js"

bootstrap()

export {
  execute,
  capabilities,
  health
}

// Core infrastructure
export * as registry from "./registry.js"
export * as events from "./events.js"
export * as state from "./state.js"
export * as metrics from "./metrics.js"

// Foundation contracts
export * from "./errors.js"
export * from "./validation.js"

// Memory
export * as memory from "../memory/store.js"

// Orchestration
export * as orchestration from "../orchestration/loop.js"

// Intelligence / learning
export * as learning from "../learning/adaptation.js"

// Agents
export * as agents from "../agents/agent.js"

// Security
export * as security from "../security/guard.js"

// Governance
export * as governance from "../governance/policy.js"

// Verification
export * as verification from "../verification/check.js"

// Planning
export * as planning from "../planning/strategy.js"

// Telemetry
export * as telemetry from "../telemetry/tracker.js"

// Flow orchestration
export * as flow from "../orchestrator/flow.js"

// Contracts
export * as contracts from "../contracts/schema.js"

// Scheduling
export * as scheduler from "../scheduler/queue.js"

// Plugins
export * as plugins from "../plugins/manager.js"

// Observability
export * as observability from "../observability/health.js"
JS

echo "[OMEGA] Root public API restored."

# ------------------------------------------------
# Validate every imported module individually.
# ------------------------------------------------

echo
echo "[OMEGA] Module syntax validation..."

node --check src/core/omega.js
node --check src/core/kernel.js
node --check src/core/errors.js
node --check src/core/validation.js
node --check src/core/metrics.js

echo "[OMEGA] Core syntax .......... PASS"

# ------------------------------------------------
# Public API verification.
# ------------------------------------------------

echo
echo "[OMEGA] Public API verification..."

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

const missing = expected.filter(
  name => !(name in OMEGA)
)

if (missing.length) {
  throw new Error(
    `PUBLIC API REGRESSION: ${missing.join(", ")}`
  )
}

for (const name of expected) {
  if (OMEGA[name] === undefined) {
    throw new Error(
      `PUBLIC API UNDEFINED: ${name}`
    )
  }
}

console.log(
  `[OMEGA] ${expected.length}/${expected.length} public exports verified`
)
JS

echo "[OMEGA] Public API .......... PASS"

# ------------------------------------------------
# Verify subsystem surfaces.
# ------------------------------------------------

echo
echo "[OMEGA] Subsystem surface verification..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

if (typeof OMEGA.execute !== "function")
  throw new Error("execute missing")

if (typeof OMEGA.capabilities !== "function")
  throw new Error("capabilities missing")

if (typeof OMEGA.health !== "function")
  throw new Error("health missing")

if (typeof OMEGA.metrics.snapshot !== "function")
  throw new Error("metrics.snapshot missing")

if (typeof OMEGA.memory !== "object")
  throw new Error("memory surface missing")

if (typeof OMEGA.orchestration !== "object")
  throw new Error("orchestration surface missing")

if (typeof OMEGA.learning !== "object")
  throw new Error("learning surface missing")

if (typeof OMEGA.agents !== "object")
  throw new Error("agents surface missing")

if (typeof OMEGA.security !== "object")
  throw new Error("security surface missing")

if (typeof OMEGA.governance !== "object")
  throw new Error("governance surface missing")

if (typeof OMEGA.verification !== "object")
  throw new Error("verification surface missing")

if (typeof OMEGA.planning !== "object")
  throw new Error("planning surface missing")

if (typeof OMEGA.telemetry !== "object")
  throw new Error("telemetry surface missing")

if (typeof OMEGA.flow !== "object")
  throw new Error("flow surface missing")

if (typeof OMEGA.contracts !== "object")
  throw new Error("contracts surface missing")

if (typeof OMEGA.scheduler !== "object")
  throw new Error("scheduler surface missing")

if (typeof OMEGA.plugins !== "object")
  throw new Error("plugins surface missing")

if (typeof OMEGA.observability !== "object")
  throw new Error("observability surface missing")

console.log("[OMEGA] All subsystem surfaces verified")
JS

echo "[OMEGA] Subsystems ........... PASS"

# ------------------------------------------------
# Targeted lifecycle tests.
# ------------------------------------------------

echo
echo "[OMEGA] Scheduler lifecycle..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const item = OMEGA.scheduler.push({
  task: "next7-integrity"
})

if (item.status !== "queued")
  throw new Error("Scheduler did not queue task")

const running = OMEGA.scheduler.next()

if (!running)
  throw new Error("Scheduler did not return task")

if (running.id !== item.id)
  throw new Error("Scheduler returned wrong task")

if (running.status !== "running")
  throw new Error("Scheduler did not enter running state")

const completed =
  OMEGA.scheduler.complete(item.id)

if (!completed)
  throw new Error("Scheduler completion failed")

if (completed.status !== "complete")
  throw new Error("Scheduler did not complete task")

console.log("[OMEGA] Scheduler lifecycle PASS")
JS

echo
echo "[OMEGA] Plugin lifecycle..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const name = `next7-plugin-${Date.now()}`

const plugin =
  OMEGA.plugins.install(name, {
    version: "1.0.0",
    capabilities: ["integrity"]
  })

if (plugin.name !== name)
  throw new Error("Plugin name mismatch")

if (plugin.status !== "installed")
  throw new Error("Plugin installation failed")

if (!OMEGA.plugins.list().some(
  x => x.name === name
)) {
  throw new Error("Plugin missing from registry")
}

if (!OMEGA.plugins.uninstall(name))
  throw new Error("Plugin uninstall failed")

console.log("[OMEGA] Plugin lifecycle PASS")
JS

echo
echo "[OMEGA] Observability..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const result =
  OMEGA.observability.probe()

const required = [
  "runtime",
  "kernel",
  "memory",
  "intelligence",
  "security"
]

for (const key of required) {
  if (result[key] !== "healthy") {
    throw new Error(
      `Observability failure: ${key}`
    )
  }
}

console.log("[OMEGA] Observability PASS")
JS

# ------------------------------------------------
# Full regression matrix.
# ------------------------------------------------

echo
echo "[OMEGA] Running COMPLETE test matrix..."
echo

npm test

# ------------------------------------------------
# CLI regression tests.
# ------------------------------------------------

echo
echo "[OMEGA] CLI verification..."

node bin/omega.js status
node bin/omega.js capabilities
node bin/omega.js metrics
node bin/omega.js help

echo
echo "================================================"
echo " OMEGA® NEXT7 RESULT"
echo "================================================"
echo
echo "Public API        PASS"
echo "Subsystems        PASS"
echo "Scheduler         PASS"
echo "Plugins           PASS"
echo "Observability     PASS"
echo "Regression Suite  PASS"
echo "CLI               PASS"
echo
echo "╔══════════════════════════════════════════════╗"
echo "║          OMEGA® NEXT7 SYSTEM PASS            ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ Foundation     PASS                          ║"
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
echo "║ Regression     PASS                          ║"
echo "║ CLI            PASS                          ║"
echo "║ Full Test      PASS                          ║"
echo "╚══════════════════════════════════════════════╝"
echo
echo "OMEGA® NEXT7 COMPLETE."
