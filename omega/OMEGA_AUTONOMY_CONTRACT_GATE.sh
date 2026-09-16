#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT GATE"
echo "============================================================"

TARGET="src/core/public-contract.js"

echo
echo "### 1. SYNTAX"
node --check "$TARGET"
echo "PASS: public-contract.js syntax"

echo
echo "### 2. PUBLIC EXPORTS"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const required = [
  ["orchestration.run", O.orchestration?.run],
  ["agents.agent", O.agents?.agent],
  ["agents.register", O.agents?.register],
  ["agents.get", O.agents?.get],
  ["agents.all", O.agents?.all],
  ["agents.remove", O.agents?.remove],
  ["security.authorize", O.security?.authorize],
  ["security.verify", O.security?.verify],
  ["security.status", O.security?.status]
]

for (const [name, value] of required) {
  if (typeof value !== "function") {
    throw new Error(`Missing public contract: ${name}`)
  }

  console.log(`PASS: ${name}`)
}
JS

echo
echo "### 3. AGENT CONTRACT"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.agents.agent(
  "contract verification",
  3
)

if (result?.type !== "agent-run") {
  throw new Error("Agent result type invalid")
}

if (result?.goal !== "contract verification") {
  throw new Error("Agent goal invalid")
}

if (result?.cycles !== 3) {
  throw new Error(
    `Expected 3 cycles, got ${result?.cycles}`
  )
}

if (result?.status !== "complete") {
  throw new Error("Agent status invalid")
}

if (
  !result?.adaptation ||
  typeof result.adaptation.confidence !== "number"
) {
  throw new Error("Agent adaptation contract invalid")
}

console.log("PASS: agents.agent()")
console.log(`PASS: cycles=${result.cycles}`)
console.log(
  `PASS: confidence=${result.adaptation.confidence}`
)

const registered = O.agents.register(
  "__omega_contract_test__",
  {
    purpose: "contract-test"
  }
)

if (
  registered.name !==
  "__omega_contract_test__"
) {
  throw new Error("Agent registration failed")
}

const found = O.agents.get(
  "__omega_contract_test__"
)

if (!found) {
  throw new Error("Agent retrieval failed")
}

if (
  O.agents.remove(
    "__omega_contract_test__"
  ) !== true
) {
  throw new Error("Agent removal failed")
}

console.log("PASS: agent registry lifecycle")
JS

echo
echo "### 4. SECURITY CONTRACT"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const safe = O.security.authorize(
  "echo safe"
)

if (
  safe.allowed !== true ||
  safe.authorized !== true
) {
  throw new Error(
    "Safe action was incorrectly denied"
  )
}

console.log("PASS: safe authorization")

const dangerous = O.security.authorize(
  "rm -rf /"
)

if (
  dangerous.allowed !== false ||
  dangerous.authorized !== false
) {
  throw new Error(
    "Destructive action was incorrectly allowed"
  )
}

if (
  dangerous.reason !== "ACTION_DENIED"
) {
  throw new Error(
    "Incorrect security denial reason"
  )
}

console.log("PASS: destructive action denied")

const verified = O.security.verify(
  "contract-target"
)

if (verified.valid !== true) {
  throw new Error(
    "Security verification failed"
  )
}

const status = O.security.status()

if (status.status !== "healthy") {
  throw new Error(
    "Security status is not healthy"
  )
}

console.log("PASS: security.verify()")
console.log("PASS: security.status()")
JS

echo
echo "### 5. ORCHESTRATION CONTRACT"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

if (
  typeof O.orchestration.run !==
  "function"
) {
  throw new Error(
    "orchestration.run missing"
  )
}

console.log(
  "PASS: orchestration.run exists"
)

console.log()
console.log(
  "NOTE: Runtime orchestration execution is"
)
console.log(
  "validated separately because it depends on"
)
console.log(
  "the scheduler/flow implementation."
)

JS

echo
echo "### 6. SOURCE INTEGRITY"

AGENT_COUNT="$(
  grep -c '^// Agents$' "$TARGET"
)"

SECURITY_COUNT="$(
  grep -c '^// Security$' "$TARGET"
)"

REGISTRY_COUNT="$(
  grep -c '^// Generic stable public namespace$' "$TARGET"
)"

if [ "$AGENT_COUNT" -ne 1 ]; then
  echo "FAIL: expected exactly one Agents contract"
  exit 1
fi

if [ "$SECURITY_COUNT" -ne 1 ]; then
  echo "FAIL: expected exactly one Security contract"
  exit 1
fi

if [ "$REGISTRY_COUNT" -ne 1 ]; then
  echo "FAIL: expected exactly one registry boundary"
  exit 1
fi

echo "PASS: exactly one Agents contract"
echo "PASS: exactly one Security contract"
echo "PASS: exactly one registry boundary"

echo
echo "============================================================"
echo " OMEGA® AUTONOMY CONTRACT GATE: PASS"
echo "============================================================"
echo
echo "NEXT:"
echo "  npm test"
echo
echo "THEN:"
echo "  npm run build"
