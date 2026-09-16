#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/omega"

echo
echo "================================================"
echo " OMEGA® NEXT8 — PRODUCTION HARDENING"
echo "================================================"
echo

# ------------------------------------------------
# 1. Baseline
# ------------------------------------------------

echo "[OMEGA] Capturing baseline..."

mkdir -p .omega/audits

node --version
npm --version

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const health = OMEGA.health()

if (health.name !== "OMEGA")
  throw new Error("Invalid OMEGA identity")

if (health.status !== "operational")
  throw new Error("OMEGA is not operational")

console.log("[OMEGA] Baseline .............. PASS")
console.log(`[OMEGA] Capabilities .......... ${health.capabilities}`)
JS

# ------------------------------------------------
# 2. Full source syntax audit
# ------------------------------------------------

echo
echo "[OMEGA] Auditing JavaScript source..."

SOURCE_FAILURE=0

while IFS= read -r -d '' file; do
  if ! node --check "$file" >/dev/null 2>&1; then
    echo "[OMEGA] SYNTAX FAILURE: $file"
    SOURCE_FAILURE=1
  fi
done < <(
  find src bin tests \
    -type f \
    -name "*.js" \
    -print0 2>/dev/null
)

if [ "$SOURCE_FAILURE" -ne 0 ]; then
  echo "[OMEGA] Source syntax ........ FAIL"
  exit 1
fi

echo "[OMEGA] Source syntax ........ PASS"

# ------------------------------------------------
# 3. Public API immutability / completeness audit
# ------------------------------------------------

echo
echo "[OMEGA] Auditing public API..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const REQUIRED = [
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

const missing = REQUIRED.filter(
  name => !(name in OMEGA)
)

if (missing.length) {
  throw new Error(
    `Missing exports: ${missing.join(", ")}`
  )
}

const undefinedExports = REQUIRED.filter(
  name => OMEGA[name] === undefined
)

if (undefinedExports.length) {
  throw new Error(
    `Undefined exports: ${undefinedExports.join(", ")}`
  )
}

console.log(
  `[OMEGA] API ${REQUIRED.length}/${REQUIRED.length} PASS`
)
JS

# ------------------------------------------------
# 4. Capability integrity
# ------------------------------------------------

echo
echo "[OMEGA] Auditing capability registry..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const capabilities = OMEGA.capabilities()

if (!Array.isArray(capabilities))
  throw new Error("Capability registry is not an array")

if (capabilities.length === 0)
  throw new Error("Capability registry is empty")

const names = new Set()

for (const capability of capabilities) {
  if (!capability || typeof capability !== "object")
    throw new Error("Invalid capability descriptor")

  if (typeof capability.name !== "string")
    throw new Error("Capability name missing")

  if (typeof capability.category !== "string")
    throw new Error(
      `Capability category missing: ${capability.name}`
    )

  if (names.has(capability.name))
    throw new Error(
      `Duplicate capability: ${capability.name}`
    )

  names.add(capability.name)
}

console.log(
  `[OMEGA] ${capabilities.length} capabilities ........ PASS`
)
JS

# ------------------------------------------------
# 5. Execution integrity
# ------------------------------------------------

echo
echo "[OMEGA] Auditing execution engine..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const before =
  OMEGA.metrics.get("execution.total")

const result =
  await OMEGA.execute(
    "simulate",
    {
      target: "NEXT8"
    }
  )

if (result.capability !== "simulate")
  throw new Error("Execution capability mismatch")

if (typeof result.duration !== "number")
  throw new Error("Execution duration missing")

if (typeof result.timestamp !== "string")
  throw new Error("Execution timestamp missing")

if (result.result === undefined)
  throw new Error("Execution result missing")

const after =
  OMEGA.metrics.get("execution.total")

if (after <= before)
  throw new Error("Execution metric did not increment")

console.log("[OMEGA] Execution integrity .... PASS")
JS

# ------------------------------------------------
# 6. Error determinism
# ------------------------------------------------

echo
echo "[OMEGA] Auditing deterministic errors..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

let passed = false

try {
  await OMEGA.execute(
    "__omega_invalid_capability__"
  )
} catch (error) {
  if (
    error.code === "UNKNOWN_CAPABILITY" &&
    error.details?.name ===
      "__omega_invalid_capability__"
  ) {
    passed = true
  } else {
    throw error
  }
}

if (!passed)
  throw new Error(
    "Unknown capability was not rejected deterministically"
  )

console.log("[OMEGA] Error determinism ...... PASS")
JS

# ------------------------------------------------
# 7. Scheduler isolation
# ------------------------------------------------

echo
echo "[OMEGA] Auditing scheduler..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const first = OMEGA.scheduler.push({
  task: "next8-a"
})

const second = OMEGA.scheduler.push({
  task: "next8-b"
})

if (first.id === second.id)
  throw new Error("Scheduler generated duplicate IDs")

if (first.status !== "queued")
  throw new Error("First task not queued")

if (second.status !== "queued")
  throw new Error("Second task not queued")

const running = OMEGA.scheduler.next()

if (!running)
  throw new Error("Scheduler returned no task")

if (running.status !== "running")
  throw new Error("Scheduler task not running")

const completed =
  OMEGA.scheduler.complete(running.id)

if (!completed)
  throw new Error("Scheduler completion returned nothing")

if (completed.status !== "complete")
  throw new Error("Scheduler completion state invalid")

console.log("[OMEGA] Scheduler integrity ...... PASS")
JS

# ------------------------------------------------
# 8. Plugin isolation
# ------------------------------------------------

echo
echo "[OMEGA] Auditing plugin manager..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const name =
  `omega-next8-${Date.now()}`

const installed =
  OMEGA.plugins.install(name, {
    version: "1.0.0",
    capabilities: ["hardening"]
  })

if (!installed)
  throw new Error("Plugin installation failed")

if (installed.name !== name)
  throw new Error("Plugin identity mismatch")

if (installed.status !== "installed")
  throw new Error("Plugin state invalid")

const listed =
  OMEGA.plugins.list()

if (!listed.some(
  plugin => plugin.name === name
)) {
  throw new Error("Installed plugin not discoverable")
}

if (!OMEGA.plugins.uninstall(name))
  throw new Error("Plugin uninstall failed")

if (OMEGA.plugins.list().some(
  plugin => plugin.name === name
)) {
  throw new Error("Plugin survived uninstall")
}

console.log("[OMEGA] Plugin isolation ........ PASS")
JS

# ------------------------------------------------
# 9. Observability integrity
# ------------------------------------------------

echo
echo "[OMEGA] Auditing observability..."

node --input-type=module <<'JS'
import * as OMEGA from "./src/core/omega.js"

const health =
  OMEGA.observability.probe()

const REQUIRED = [
  "runtime",
  "kernel",
  "memory",
  "intelligence",
  "security"
]

for (const key of REQUIRED) {
  if (health[key] !== "healthy") {
    throw new Error(
      `Subsystem unhealthy: ${key}`
    )
  }
}

console.log("[OMEGA] Observability .......... PASS")
JS

# ------------------------------------------------
# 10. Full regression
# ------------------------------------------------

echo
echo "[OMEGA] Running full regression matrix..."
echo

npm test

# ------------------------------------------------
# 11. CLI verification
# ------------------------------------------------

echo
echo "[OMEGA] CLI verification..."

node bin/omega.js status >/dev/null
node bin/omega.js capabilities >/dev/null
node bin/omega.js metrics >/dev/null
node bin/omega.js help >/dev/null

echo "[OMEGA] CLI .................... PASS"

# ------------------------------------------------
# 12. Package integrity
# ------------------------------------------------

echo
echo "[OMEGA] Package integrity..."

node --input-type=module <<'JS'
import fs from "node:fs"

const required = [
  "package.json",
  "src/core/omega.js",
  "src/core/kernel.js",
  "src/core/errors.js",
  "src/core/validation.js",
  "src/core/metrics.js",
  "bin/omega.js"
]

for (const file of required) {
  if (!fs.existsSync(file)) {
    throw new Error(
      `Required file missing: ${file}`
    )
  }
}

const pkg =
  JSON.parse(
    fs.readFileSync(
      "package.json",
      "utf8"
    )
  )

if (!pkg.name)
  throw new Error("Package name missing")

if (!pkg.version)
  throw new Error("Package version missing")

console.log(
  `[OMEGA] Package ${pkg.name}@${pkg.version} .... PASS`
)
JS

# ------------------------------------------------
# FINAL
# ------------------------------------------------

echo
echo "================================================"
echo " OMEGA® NEXT8 RESULT"
echo "================================================"
echo
echo "Baseline             PASS"
echo "Source Syntax        PASS"
echo "Public API           PASS"
echo "Capabilities         PASS"
echo "Execution            PASS"
echo "Error Determinism    PASS"
echo "Scheduler             PASS"
echo "Plugins               PASS"
echo "Observability         PASS"
echo "Regression Suite      PASS"
echo "CLI                   PASS"
echo "Package Integrity     PASS"
echo
echo "╔══════════════════════════════════════════════╗"
echo "║          OMEGA® NEXT8 SYSTEM PASS            ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ Architecture   HARDENED                      ║"
echo "║ API            STABLE                        ║"
echo "║ Execution      VERIFIED                      ║"
echo "║ Scheduler      VERIFIED                      ║"
echo "║ Plugins        VERIFIED                      ║"
echo "║ Observability  VERIFIED                      ║"
echo "║ Security       VERIFIED                      ║"
echo "║ Regression     VERIFIED                      ║"
echo "║ CLI            VERIFIED                      ║"
echo "║ Package        VERIFIED                      ║"
echo "╚══════════════════════════════════════════════╝"
echo
echo "OMEGA® NEXT8 COMPLETE."
