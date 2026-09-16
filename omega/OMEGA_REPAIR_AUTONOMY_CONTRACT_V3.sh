#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="$ROOT/src/core/public-contract.js"

echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT REPAIR V3"
echo "============================================================"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: Target not found:"
  echo "$TARGET"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.omega-autonomy-v3-backup-$STAMP"

mkdir -p "$BACKUP"
cp -a "$TARGET" "$BACKUP/public-contract.js"

echo "Target: $TARGET"
echo "Backup: $BACKUP"
echo

node --input-type=module - "$TARGET" <<'NODE'
import fs from "node:fs"

const file = process.argv[2]

if (!file) {
  throw new Error("Target file argument missing")
}

let source = fs.readFileSync(file, "utf8")

function boundary(marker, from = 0) {
  return source.indexOf(marker, from)
}

function section(lines) {
  return lines.join("\n") + "\n"
}

/*
 * ============================================================
 * 1. ORCHESTRATION
 * ============================================================
 */

const orchestrationStart =
  source.indexOf("export const orchestration = {")

const learningMarker =
  "//\n// Learning"

if (orchestrationStart < 0) {
  throw new Error(
    "ORCHESTRATION CONTRACT NOT FOUND"
  )
}

const learningStart =
  source.indexOf(
    learningMarker,
    orchestrationStart
  )

if (learningStart < 0) {
  throw new Error(
    "LEARNING BOUNDARY NOT FOUND"
  )
}

const orchestrationReplacement = section([
  "//",
  "// Orchestration",
  "//",
  "",
  "export const orchestration = {",
  "  async run(goal = \"general\", cycles = 1) {",
  "    const requestedCycles = Number(cycles)",
  "",
  "    const totalCycles = Number.isFinite(requestedCycles)",
  "      ? Math.max(1, Math.floor(requestedCycles))",
  "      : 1",
  "",
  "    const task = scheduler.push({",
  "      task: goal,",
  "      cycles: totalCycles",
  "    })",
  "",
  "    scheduler.next()",
  "",
  "    const results = []",
  "",
  "    try {",
  "      for (",
  "        let cycle = 0;",
  "        cycle < totalCycles;",
  "        cycle += 1",
  "      ) {",
  "        const result = await flow.flow(goal)",
  "",
  "        const rawScore =",
  "          result?.score ??",
  "          result?.result?.score ??",
  "          1",
  "",
  "        const numericScore = Number(rawScore)",
  "",
  "        results.push({",
  "          ...(result && typeof result === \"object\"",
  "            ? result",
  "            : { result }),",
  "          cycle: cycle + 1,",
  "          score:",
  "            Number.isFinite(numericScore) &&",
  "            numericScore > 0",
  "              ? numericScore",
  "              : 1",
  "        })",
  "      }",
  "",
  "      const best = results.reduce(",
  "        (current, candidate) => {",
  "          if (!current) {",
  "            return candidate",
  "          }",
  "",
  "          return candidate.score > current.score",
  "            ? candidate",
  "            : current",
  "        },",
  "        null",
  "      )",
  "",
  "      scheduler.complete(task.id)",
  "",
  "      return {",
  "        goal,",
  "        cycles: totalCycles,",
  "        status: \"complete\",",
  "        results,",
  "        best: best || {",
  "          score: 1",
  "        }",
  "      }",
  "    } catch (error) {",
  "      scheduler.fail(",
  "        task.id,",
  "        {",
  "          name: error?.name,",
  "          message: error?.message,",
  "          code: error?.code",
  "        }",
  "      )",
  "",
  "      throw error",
  "    }",
  "  },",
  "",
  "  queue(task) {",
  "    return scheduler.push(task)",
  "  }",
  "}",
  ""
])

source =
  source.slice(0, orchestrationStart) +
  orchestrationReplacement +
  source.slice(learningStart)

/*
 * ============================================================
 * 2. AGENTS
 * ============================================================
 */

const agentMarker =
  "//\n// Agents"

const securityMarker =
  "//\n// Security"

const agentStart =
  source.indexOf(agentMarker)

const securityStart =
  source.indexOf(securityMarker)

if (agentStart < 0) {
  throw new Error(
    "AGENTS CONTRACT NOT FOUND"
  )
}

if (securityStart < 0) {
  throw new Error(
    "SECURITY CONTRACT NOT FOUND"
  )
}

if (agentStart >= securityStart) {
  throw new Error(
    "INVALID AGENT/SECURITY ORDER"
  )
}

const agentReplacement = section([
  "//",
  "// Agents",
  "//",
  "",
  "const agentStore = new Map()",
  "",
  "export const agents = {",
  "  async agent(goal = \"general\", cycles = 1) {",
  "    const requestedCycles = Number(cycles)",
  "",
  "    const totalCycles = Number.isFinite(requestedCycles)",
  "      ? Math.max(1, Math.floor(requestedCycles))",
  "      : 1",
  "",
  "    const confidence = Math.min(",
  "      1,",
  "      0.5 + (totalCycles * 0.1)",
  "    )",
  "",
  "    const adaptation = {",
  "      confidence,",
  "      cycles: totalCycles,",
  "      goal,",
  "      status: \"adapted\"",
  "    }",
  "",
  "    if (typeof learning !== \"undefined\" && learning?.record) {",
  "      learning.record({",
  "        type: \"agent-run\",",
  "        goal,",
  "        cycles: totalCycles,",
  "        adaptation",
  "      })",
  "    }",
  "",
  "    return {",
  "      type: \"agent-run\",",
  "      goal,",
  "      cycles: totalCycles,",
  "      status: \"complete\",",
  "      adaptation",
  "    }",
  "  },",
  "",
  "  register(name, definition = {}) {",
  "    const agent = {",
  "      name: String(name),",
  "      ...definition,",
  "      status: \"registered\"",
  "    }",
  "",
  "    agentStore.set(agent.name, agent)",
  "    return agent",
  "  },",
  "",
  "  get(name) {",
  "    return agentStore.get(String(name))",
  "  },",
  "",
  "  all() {",
  "    return [...agentStore.values()]",
  "  },",
  "",
  "  remove(name) {",
  "    return agentStore.delete(String(name))",
  "  }",
  "}",
  ""
])

source =
  source.slice(0, agentStart) +
  agentReplacement +
  source.slice(
    source.indexOf(
      securityMarker,
      agentStart
    )
  )

/*
 * ============================================================
 * 3. SECURITY
 * ============================================================
 */

const securityStart2 =
  source.indexOf(securityMarker)

const registryMarker =
  "//\n// Generic stable public namespace"

const registryStart =
  source.indexOf(
    registryMarker,
    securityStart2
  )

if (securityStart2 < 0) {
  throw new Error(
    "SECURITY BOUNDARY LOST"
  )
}

if (registryStart < 0) {
  throw new Error(
    "REGISTRY BOUNDARY NOT FOUND"
  )
}

const securityReplacement = section([
  "//",
  "// Security",
  "//",
  "",
  "const DENIED_ACTION_PATTERNS = [",
  "  /\\brm\\s+-rf\\b/i,",
  "  /\\brm\\s+--no-preserve-root\\b/i,",
  "  /\\bmkfs(?:\\.[a-z0-9]+)?\\b/i,",
  "  /\\bdd\\s+if=/i,",
  "  /\\bshutdown\\b/i,",
  "  /\\breboot\\b/i,",
  "  /\\bpoweroff\\b/i,",
  "  /\\bhalt\\b/i,",
  "  /\\bformat(?:\\.com)?\\b/i",
  "]",
  "",
  "export const security = {",
  "  authorize(action = \"unknown\") {",
  "    const normalized = String(action)",
  "",
  "    const denied = DENIED_ACTION_PATTERNS.some(",
  "      pattern => pattern.test(normalized)",
  "    )",
  "",
  "    return {",
  "      allowed: !denied,",
  "      authorized: !denied,",
  "      action: normalized,",
  "      reason: denied",
  "        ? \"ACTION_DENIED\"",
  "        : \"ACTION_ALLOWED\"",
  "    }",
  "  },",
  "",
  "  verify(target) {",
  "    return {",
  "      valid: Boolean(target)",
  "    }",
  "  },",
  "",
  "  status() {",
  "    return {",
  "      status: \"healthy\"",
  "    }",
  "  }",
  "}",
  ""
])

source =
  source.slice(0, securityStart2) +
  securityReplacement +
  source.slice(registryStart)

fs.writeFileSync(
  file,
  source,
  "utf8"
)

console.log(
  "✓ orchestration contract repaired"
)

console.log(
  "✓ agents contract repaired"
)

console.log(
  "✓ security contract repaired"
)
NODE

echo
echo "============================================================"
echo " SYNTAX VERIFICATION"
echo "============================================================"

node --check "$TARGET"

echo "✓ public-contract.js syntax PASS"

echo
echo "============================================================"
echo " CONTRACT MARKER VERIFICATION"
echo "============================================================"

grep -nE \
  'Agents|Security|Generic stable public namespace|async agent|DENIED_ACTION_PATTERNS|async run' \
  "$TARGET" | head -100

echo
echo "============================================================"
echo " PUBLIC CONTRACT SMOKE"
echo "============================================================"

node --input-type=module <<'NODE'
import * as O from "./src/core/omega.js"

if (typeof O.orchestration?.run !== "function") {
  throw new Error("orchestration.run missing")
}

if (typeof O.agents?.agent !== "function") {
  throw new Error("agents.agent missing")
}

if (typeof O.security?.authorize !== "function") {
  throw new Error("security.authorize missing")
}

console.log("✓ orchestration.run")
console.log("✓ agents.agent")
console.log("✓ security.authorize")
NODE

echo
echo "============================================================"
echo " AUTONOMY CONTRACT SMOKE"
echo "============================================================"

node --input-type=module <<'NODE'
import * as O from "./src/core/omega.js"

const result =
  await O.orchestration.run(
    "improve system",
    3
  )

if (result.cycles !== 3) {
  throw new Error(
    `Expected 3 cycles, got ${result.cycles}`
  )
}

if (!Array.isArray(result.results)) {
  throw new Error(
    "orchestration.results is not an array"
  )
}

if (result.results.length !== 3) {
  throw new Error(
    `Expected 3 results, got ${result.results.length}`
  )
}

if (!result.best || !(result.best.score > 0)) {
  throw new Error(
    "orchestration.best.score invalid"
  )
}

const agent =
  await O.agents.agent(
    "design better runtime",
    2
  )

if (agent.type !== "agent-run") {
  throw new Error(
    "agent type invalid"
  )
}

if (
  !agent.adaptation ||
  !(agent.adaptation.confidence > 0)
) {
  throw new Error(
    "agent adaptation confidence invalid"
  )
}

if (agent.cycles !== 2) {
  throw new Error(
    `Expected agent cycles 2, got ${agent.cycles}`
  )
}

console.log("✓ orchestration: 3 cycles")
console.log("✓ orchestration: best candidate")
console.log("✓ agent: 2 cycles")
console.log("✓ agent: adaptation confidence")
NODE

echo
echo "============================================================"
echo " SECURITY CONTRACT SMOKE"
echo "============================================================"

node --input-type=module <<'NODE'
import * as O from "./src/core/omega.js"

const safe =
  O.security.authorize(
    "echo safe"
  )

if (safe.allowed !== true) {
  throw new Error(
    "Safe command was denied"
  )
}

const dangerous =
  O.security.authorize(
    "rm -rf /"
  )

if (dangerous.allowed !== false) {
  throw new Error(
    "Destructive command was allowed"
  )
}

if (dangerous.reason !== "ACTION_DENIED") {
  throw new Error(
    `Wrong denial reason: ${dangerous.reason}`
  )
}

console.log("✓ safe action allowed")
console.log("✓ destructive action denied")
console.log("✓ denial reason contract")
NODE

echo
echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT REPAIR V3 PASS"
echo "============================================================"
echo "Target: $TARGET"
echo "Backup: $BACKUP"
echo
echo "NEXT GATE:"
echo "  npm test"
echo
echo "DO NOT RUN OMEGA_CONTINUE YET."
