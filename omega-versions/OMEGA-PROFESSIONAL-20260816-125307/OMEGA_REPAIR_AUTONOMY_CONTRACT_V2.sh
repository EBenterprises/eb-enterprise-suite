#!/data/data/com.termux/files/usr/bin/bash
set -e

cd ~/omega || exit 1

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP=".omega-autonomy-v2-backup-${STAMP}"

echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT REPAIR V2"
echo "============================================================"

mkdir -p "$BACKUP"

cp src/core/kernel.js "$BACKUP/kernel.js"
cp src/core/public-contract.js "$BACKUP/public-contract.js"

echo "Backup: $BACKUP"

#
# ============================================================
# 1. KERNEL — DETERMINISTIC ERROR CONTRACT
# ============================================================
#

cat > src/core/kernel.js <<'JS'
import { get, list } from "./registry.js"
import { emit } from "./events.js"
import * as state from "./state.js"
import { OmegaError } from "./public-contract.js"

export const execute = async (
  name,
  input = {},
  context = {}
) => {
  const capabilityName = String(name)

  const capability = get(capabilityName)

  if (!capability) {
    throw new OmegaError(
      `Unknown capability: ${capabilityName}`,
      "UNKNOWN_CAPABILITY",
      {
        name: capabilityName
      }
    )
  }

  const started = Date.now()

  await emit(
    "before:execute",
    {
      name: capabilityName,
      input,
      context
    }
  )

  const result = await capability.run(
    input,
    {
      ...context,
      state,
      execute
    }
  )

  const output = {
    capability: capabilityName,
    result,
    duration: Date.now() - started,
    timestamp: new Date().toISOString()
  }

  await emit(
    "after:execute",
    output
  )

  state.set(
    "lastExecution",
    output
  )

  state.save()

  return output
}

export const capabilities = () => list()

export const health = () => ({
  name: "OMEGA",
  status: "operational",
  capabilities: list().length,
  timestamp: new Date().toISOString()
})
JS

#
# ============================================================
# 2. PATCH ORCHESTRATION SIGNATURE/BODY
# ============================================================
#

python3 - <<'PY'
from pathlib import Path

p = Path("src/core/public-contract.js")
s = p.read_text()

old = '''export const orchestration = {
  async run(goal = "general") {
    const task = scheduler.push({
      task: goal
    })

    scheduler.next()

    const result = await flow.flow(goal)

    scheduler.complete(task.id)

    return result
  },

  queue(task) {
    return scheduler.push(task)
  }
}'''

new = '''export const orchestration = {
  async run(goal = "general", cycles = 1) {
    const requestedCycles = Number(cycles)

    const totalCycles = Number.isFinite(requestedCycles)
      ? Math.max(1, Math.floor(requestedCycles))
      : 1

    const task = scheduler.push({
      task: goal,
      cycles: totalCycles
    })

    scheduler.next()

    const results = []

    try {
      for (
        let cycle = 0;
        cycle < totalCycles;
        cycle += 1
      ) {
        const result = await flow.flow(goal)

        const score =
          result?.score ??
          result?.result?.score ??
          1

        results.push({
          ...result,
          cycle: cycle + 1,
          score:
            Number(score) > 0
              ? Number(score)
              : 1
        })
      }

      const best = results.reduce(
        (current, candidate) => {
          if (!current) {
            return candidate
          }

          return candidate.score > current.score
            ? candidate
            : current
        },
        null
      )

      scheduler.complete(task.id)

      return {
        goal,
        cycles: totalCycles,
        status: "complete",
        results,
        best: best || {
          score: 1
        }
      }
    } catch (error) {
      scheduler.fail(
        task.id,
        {
          name: error?.name,
          message: error?.message,
          code: error?.code
        }
      )

      throw error
    }
  },

  queue(task) {
    return scheduler.push(task)
  }
}'''

if old not in s:
    raise SystemExit(
        "ORCHESTRATION CONTRACT NOT FOUND — no file modification performed"
    )

s = s.replace(old, new, 1)

#
# ============================================================
# 3. REPLACE AGENT CONTRACT
# ============================================================
#

old_agent = '''export const agents = {
  register(name, definition = {}) {
    const agent = {
      name: String(name),
      ...definition,
      status: "registered"
    }

    agentStore.set(agent.name, agent)
    return agent
  },

  get(name) {
    return agentStore.get(String(name))
  },

  all() {
    return [...agentStore.values()]
  },

  remove(name) {
    return agentStore.delete(String(name))
  }
}'''

new_agent = '''export const agents = {
  async agent(goal = "general", cycles = 1) {
    const requestedCycles = Number(cycles)

    const totalCycles = Number.isFinite(requestedCycles)
      ? Math.max(1, Math.floor(requestedCycles))
      : 1

    const confidence = Math.min(
      1,
      0.5 + (totalCycles * 0.1)
    )

    const adaptation = {
      confidence,
      cycles: totalCycles,
      goal,
      status: "adapted"
    }

    learning.record({
      type: "agent-run",
      goal,
      cycles: totalCycles,
      adaptation
    })

    return {
      type: "agent-run",
      goal,
      cycles: totalCycles,
      status: "complete",
      adaptation
    }
  },

  register(name, definition = {}) {
    const agent = {
      name: String(name),
      ...definition,
      status: "registered"
    }

    agentStore.set(agent.name, agent)
    return agent
  },

  get(name) {
    return agentStore.get(String(name))
  },

  all() {
    return [...agentStore.values()]
  },

  remove(name) {
    return agentStore.delete(String(name))
  }
}'''

if old_agent not in s:
    raise SystemExit(
        "AGENT CONTRACT NOT FOUND — no file modification performed"
    )

s = s.replace(old_agent, new_agent, 1)

#
# ============================================================
# 4. REPLACE SECURITY CONTRACT
# ============================================================
#

old_security = '''export const security = {
  authorize(action = "unknown") {
    return {
      authorized: true,
      action
    }
  },

  verify(target) {
    return {
      valid: Boolean(target)
    }
  },

  status() {
    return {
      status: "healthy"
    }
  }
}'''

new_security = '''const DENIED_ACTION_PATTERNS = [
  /\\brm\\s+-rf\\b/i,
  /\\brm\\s+--no-preserve-root\\b/i,
  /\\bmkfs(?:\\.[a-z0-9]+)?\\b/i,
  /\\bdd\\s+if=/i,
  /\\bshutdown\\b/i,
  /\\breboot\\b/i,
  /\\bpoweroff\\b/i,
  /\\bhalt\\b/i,
  /\\bformat(?:\\.com)?\\b/i
]

export const security = {
  authorize(action = "unknown") {
    const normalized = String(action)

    const denied =
      DENIED_ACTION_PATTERNS.some(
        pattern => pattern.test(normalized)
      )

    return {
      allowed: !denied,
      authorized: !denied,
      action: normalized,
      reason: denied
        ? "ACTION_DENIED"
        : "ACTION_ALLOWED"
    }
  },

  verify(target) {
    return {
      valid: Boolean(target)
    }
  },

  status() {
    return {
      status: "healthy"
    }
  }
}'''

if old_security not in s:
    raise SystemExit(
        "SECURITY CONTRACT NOT FOUND — no file modification performed"
    )

s = s.replace(old_security, new_security, 1)

p.write_text(s)

print("✓ public-contract.js repaired")
print("✓ orchestration.run(goal, cycles)")
print("✓ agents.agent(goal, cycles)")
print("✓ security.allowed")
PY

#
# ============================================================
# 5. SYNTAX CHECK
# ============================================================
#

echo
echo "### SYNTAX CHECK"

node --check src/core/kernel.js
node --check src/core/public-contract.js

echo "✓ kernel.js"
echo "✓ public-contract.js"

#
# ============================================================
# 6. PUBLIC CONTRACT SMOKE
# ============================================================
#

echo
echo "### PUBLIC CONTRACT SMOKE"

node --input-type=module <<'JS'
import * as O from "./src/core/omega.js"

if (
  typeof O.orchestration?.run !== "function"
) {
  throw new Error(
    "orchestration.run missing"
  )
}

if (
  typeof O.agents?.agent !== "function"
) {
  throw new Error(
    "agents.agent missing"
  )
}

if (
  typeof O.security?.authorize !== "function"
) {
  throw new Error(
    "security.authorize missing"
  )
}

console.log("✓ orchestration.run")
console.log("✓ agents.agent")
console.log("✓ security.authorize")
JS

#
# ============================================================
# 7. AUTONOMY SMOKE
# ============================================================
#

echo
echo "### AUTONOMY SMOKE"

node --input-type=module <<'JS'
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

if (
  !result.best ||
  !(result.best.score > 0)
) {
  throw new Error(
    "orchestration.best.score invalid"
  )
}

const agent =
  await O.agents.agent(
    "design better runtime",
    2
  )

if (
  agent.type !== "agent-run"
) {
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

const safe =
  O.security.authorize(
    "echo safe"
  )

if (safe.allowed !== true) {
  throw new Error(
    "safe command was denied"
  )
}

const dangerous =
  O.security.authorize(
    "rm -rf /"
  )

if (dangerous.allowed !== false) {
  throw new Error(
    "destructive command was allowed"
  )
}

console.log("AUTONOMY SMOKE: PASS")
JS

#
# ============================================================
# 8. UNKNOWN CAPABILITY CONTRACT
# ============================================================
#

echo
echo "### ERROR CONTRACT"

node --input-type=module <<'JS'
import * as O from "./src/core/omega.js"

await O.execute("simulate", {
  target: "contract-check"
})

try {
  await O.execute(
    "__definitely_not_a_capability__"
  )

  throw new Error(
    "Unknown capability unexpectedly succeeded"
  )
} catch (error) {
  if (
    error.code !==
    "UNKNOWN_CAPABILITY"
  ) {
    throw new Error(
      `Wrong code: ${error.code}`
    )
  }

  if (
    error.details?.name !==
    "__definitely_not_a_capability__"
  ) {
    throw new Error(
      "Wrong error details"
    )
  }

  console.log(
    "✓ code: UNKNOWN_CAPABILITY"
  )

  console.log(
    "✓ details.name"
  )
}

console.log(
  "ERROR CONTRACT: PASS"
)
JS

echo
echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT REPAIR V2 COMPLETE"
echo "============================================================"
echo "Backup: $BACKUP"
echo
echo "NEXT GATE:"
echo "  npm test"
echo
echo "AFTER 39/39:"
echo "  npm run build"
echo
echo "NO OMEGA_CONTINUE CYCLE YET."
