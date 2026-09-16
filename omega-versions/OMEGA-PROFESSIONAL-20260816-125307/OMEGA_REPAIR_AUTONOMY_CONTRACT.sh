#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="$ROOT/src/core/public-contract.js"

echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT REPAIR"
echo "============================================================"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: Target file not found:"
  echo "  $TARGET"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.omega-autonomy-repair-$STAMP"

mkdir -p "$BACKUP"
cp -a "$TARGET" "$BACKUP/public-contract.js"

echo "Backup: $(basename "$BACKUP")"
echo "Target: $TARGET"

node --check "$TARGET"

node --input-type=module - "$TARGET" <<'NODE'
import fs from "node:fs"

const file = process.argv[2]

if (!file) {
  throw new Error("Missing target file")
}

const source = fs.readFileSync(file, "utf8")

const agentMarker = "//\n// Agents"
const securityMarker = "//\n// Security"
const registryMarker = "//\n// Generic stable public namespace"

const agentStart = source.indexOf(agentMarker)
const securityStart = source.indexOf(securityMarker)
const registryStart = source.indexOf(registryMarker)

if (agentStart < 0) {
  throw new Error("Agents contract boundary not found")
}

if (securityStart < 0) {
  throw new Error("Security contract boundary not found")
}

if (registryStart < 0) {
  throw new Error("Public namespace boundary not found")
}

if (!(agentStart < securityStart && securityStart < registryStart)) {
  throw new Error(
    "Contract boundaries are not ordered as expected"
  )
}

function block(lines) {
  return lines.join("\n") + "\n"
}

const agents = block([
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

const security = block([
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

const repaired =
  source.slice(0, agentStart) +
  agents +
  source.slice(securityStart, securityStart)

const afterAgents =
  source.slice(0, agentStart) +
  agents +
  source.slice(securityStart)

const securityStartAfterAgents =
  afterAgents.indexOf(securityMarker)

const registryStartAfterAgents =
  afterAgents.indexOf(
    registryMarker,
    securityStartAfterAgents
  )

if (
  securityStartAfterAgents < 0 ||
  registryStartAfterAgents < 0
) {
  throw new Error(
    "Could not recalculate contract boundaries after Agents repair"
  )
}

const finalSource =
  afterAgents.slice(0, securityStartAfterAgents) +
  security +
  afterAgents.slice(registryStartAfterAgents)

fs.writeFileSync(file, finalSource)

console.log("Public autonomy contracts repaired.")
NODE

echo
echo "============================================================"
echo " VERIFYING"
echo "============================================================"

node --check "$TARGET"

echo
echo "=== FINAL CONTRACT MARKERS ==="
grep -nE \
  'Agents|Security|Generic stable public namespace|agentStore|DENIED_ACTION_PATTERNS' \
  "$TARGET" | head -100

echo
echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT REPAIR COMPLETE"
echo "============================================================"
echo "Target : $TARGET"
echo "Backup : $BACKUP"
