#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STATE="$ROOT/.omega/autonomous-engine"
mkdir -p "$STATE"/{checkpoints,runs,proposals,reports}

RUN_ID="$(date +%Y%m%d_%H%M%S)"
RUN="$STATE/runs/$RUN_ID"

mkdir -p "$RUN"

echo "============================================================"
echo " OMEGA® AUTONOMOUS ENGINEERING LOOP"
echo "============================================================"
echo "RUN: $RUN_ID"
echo

fail() {
  echo
  echo "FAIL: $1"
  echo "RUN: $RUN"
  exit 1
}

echo "### PHASE 1 — BASELINE"

git rev-parse HEAD > "$RUN/baseline.commit"

BASELINE="$(cat "$RUN/baseline.commit")"

echo "Baseline: $BASELINE"

echo
echo "### PHASE 2 — HEALTH"

node --check src/core/public-contract.js \
  > "$RUN/syntax.log" 2>&1 \
  || fail "source syntax"

npm test \
  > "$RUN/tests.log" 2>&1 \
  || fail "regression tests"

echo "PASS: source syntax"
echo "PASS: regression suite"

echo
echo "### PHASE 3 — AUTONOMOUS REASONING"

node --input-type=module > "$RUN/agent.json" <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.agents.agent(
  "identify the highest-value safe engineering advancement available to OMEGA",
  5
)

if (result?.status !== "complete") {
  throw new Error("Autonomous reasoning did not complete")
}

if (result?.cycles !== 5) {
  throw new Error("Autonomous reasoning cycle contract failed")
}

if (
  !result?.adaptation ||
  typeof result.adaptation.confidence !== "number"
) {
  throw new Error("Autonomous adaptation contract failed")
}

console.log(JSON.stringify(result, null, 2))
JS

echo "PASS: autonomous reasoning"

echo
echo "### PHASE 4 — ORCHESTRATION"

node --input-type=module > "$RUN/orchestration.json" <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.orchestration.run(
  "perform a safe autonomous engineering advancement assessment",
  5
)

if (result?.status !== "complete") {
  throw new Error("Orchestration did not complete")
}

if (result?.cycles !== 5) {
  throw new Error("Orchestration cycle contract failed")
}

if (!Array.isArray(result?.results)) {
  throw new Error("Orchestration result collection missing")
}

if (result.results.length !== 5) {
  throw new Error("Orchestration result count failed")
}

if (!result.best) {
  throw new Error("No best candidate produced")
}

console.log(JSON.stringify(result, null, 2))
JS

echo "PASS: orchestration"

echo
echo "### PHASE 5 — SECURITY BOUNDARY"

node --input-type=module > "$RUN/security.json" <<'JS'
import * as O from "./src/core/public-contract.js"

const safe = O.security.authorize(
  "OMEGA autonomous engineering verification"
)

if (
  safe.allowed !== true ||
  safe.authorized !== true
) {
  throw new Error("Safe operation rejected")
}

const dangerous = O.security.authorize(
  "rm -rf /"
)

if (
  dangerous.allowed !== false ||
  dangerous.authorized !== false
) {
  throw new Error("Destructive operation escaped security boundary")
}

if (dangerous.reason !== "ACTION_DENIED") {
  throw new Error("Incorrect security denial reason")
}

const status = O.security.status()

if (status.status !== "healthy") {
  throw new Error("Security system unhealthy")
}

console.log(JSON.stringify({
  safe,
  dangerous,
  status
}, null, 2))
JS

echo "PASS: security boundary"

echo
echo "### PHASE 6 — PRODUCTION VERIFICATION"

npm run build \
  > "$RUN/build.log" 2>&1 \
  || fail "production build"

echo "PASS: production build"

echo
echo "### PHASE 7 — ADVANCEMENT DECISION"

cat > "$RUN/DECISION.md" <<DECISION
# OMEGA® Autonomous Advancement Decision

Run:
$RUN_ID

Baseline:
$BASELINE

Source:
PASS

Regression:
PASS

Autonomous reasoning:
PASS

Orchestration:
PASS

Security:
PASS

Production build:
PASS

## Promotion Rule

OMEGA® MUST NOT mutate its production baseline merely because
an autonomous candidate exists.

A candidate must:

1. Be generated.
2. Be evaluated.
3. Pass security.
4. Pass regression.
5. Pass production build.
6. Be checkpointed.
7. Be explicitly promoted.

Current run:
VERIFIED

Promotion:
PENDING EXPLICIT PROMOTION
DECISION

echo "PASS: advancement decision recorded"

echo
echo "### PHASE 8 — CHECKPOINT"

cp "$RUN/agent.json" \
  "$STATE/checkpoints/$RUN_ID-agent.json"

cp "$RUN/orchestration.json" \
  "$STATE/checkpoints/$RUN_ID-orchestration.json"

cp "$RUN/security.json" \
  "$STATE/checkpoints/$RUN_ID-security.json"

cp "$RUN/DECISION.md" \
  "$STATE/checkpoints/$RUN_ID-decision.md"

echo "PASS: checkpoint"

echo
echo "============================================================"
echo " OMEGA® AUTONOMOUS ENGINEERING LOOP: PASS"
echo "============================================================"
echo
echo "No unverified production mutation was performed."
echo
echo "RUN:"
echo "  $RUN"
echo
echo "BASELINE:"
echo "  $BASELINE"
echo
echo "STATUS:"
echo "  VERIFIED — CANDIDATE ADVANCEMENT READY"
echo
