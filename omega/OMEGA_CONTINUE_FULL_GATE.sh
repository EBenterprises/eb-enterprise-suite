#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d_%H%M%S)"
CHECKPOINT="$ROOT/.omega-release-$STAMP"
TARGET="$ROOT/src/core/public-contract.js"

echo "============================================================"
echo " OMEGA® FULL CONTINUATION + RELEASE GATE"
echo "============================================================"
echo "ROOT: $ROOT"
echo "STAMP: $STAMP"
echo

if [ ! -f "$TARGET" ]; then
  echo "FATAL: public-contract.js not found"
  exit 1
fi

mkdir -p "$CHECKPOINT"

echo "### 1. CAPTURE CURRENT STATE"
git status --short > "$CHECKPOINT/git-status.txt" || true
git diff > "$CHECKPOINT/git-diff.patch" || true
git diff --stat > "$CHECKPOINT/git-diff-stat.txt" || true

cp -a "$TARGET" "$CHECKPOINT/public-contract.js"

echo "PASS: release checkpoint created"
echo "CHECKPOINT: $CHECKPOINT"
echo

echo "### 2. NODE / NPM ENVIRONMENT"
node --version
npm --version
echo "PASS: Node/npm available"
echo

echo "### 3. PUBLIC CONTRACT SYNTAX"
node --check "$TARGET"
echo "PASS: public-contract.js syntax"
echo

echo "### 4. PUBLIC CONTRACT EXPORT GATE"
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
    throw new Error(`Missing contract: ${name}`)
  }

  console.log(`PASS: ${name}`)
}
JS
echo

echo "### 5. SOURCE INTEGRITY"

AGENTS="$(grep -c '^// Agents$' "$TARGET")"
SECURITY="$(grep -c '^// Security$' "$TARGET")"
REGISTRY="$(grep -c '^// Generic stable public namespace$' "$TARGET")"

[ "$AGENTS" -eq 1 ] || {
  echo "FAIL: Agents contract count=$AGENTS"
  exit 1
}

[ "$SECURITY" -eq 1 ] || {
  echo "FAIL: Security contract count=$SECURITY"
  exit 1
}

[ "$REGISTRY" -eq 1 ] || {
  echo "FAIL: Registry boundary count=$REGISTRY"
  exit 1
}

echo "PASS: one Agents contract"
echo "PASS: one Security contract"
echo "PASS: one registry boundary"
echo

echo "### 6. AGENT RUNTIME GATE"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.agents.agent(
  "full continuation verification",
  5
)

if (result.type !== "agent-run") {
  throw new Error("Invalid agent result type")
}

if (result.cycles !== 5) {
  throw new Error(`Expected 5 cycles, got ${result.cycles}`)
}

if (result.status !== "complete") {
  throw new Error("Agent did not complete")
}

if (
  !result.adaptation ||
  typeof result.adaptation.confidence !== "number"
) {
  throw new Error("Invalid adaptation contract")
}

console.log("PASS: agent execution")
console.log(`PASS: cycles=${result.cycles}`)
console.log(`PASS: confidence=${result.adaptation.confidence}`)

const name = "__omega_full_gate_agent__"

O.agents.register(name, {
  purpose: "full-gate"
})

if (!O.agents.get(name)) {
  throw new Error("Agent registration/retrieval failed")
}

if (!O.agents.remove(name)) {
  throw new Error("Agent removal failed")
}

console.log("PASS: agent lifecycle")
JS
echo

echo "### 7. SECURITY RUNTIME GATE"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const safe = O.security.authorize("echo OMEGA")

if (
  safe.allowed !== true ||
  safe.authorized !== true
) {
  throw new Error("Safe operation rejected")
}

const dangerous = O.security.authorize("rm -rf /")

if (
  dangerous.allowed !== false ||
  dangerous.authorized !== false
) {
  throw new Error("Destructive operation was allowed")
}

if (dangerous.reason !== "ACTION_DENIED") {
  throw new Error("Incorrect security denial reason")
}

if (
  O.security.verify("omega-runtime").valid !== true
) {
  throw new Error("Security verification failed")
}

if (
  O.security.status().status !== "healthy"
) {
  throw new Error("Security status unhealthy")
}

console.log("PASS: safe authorization")
echo=""

echo "PASS: destructive authorization denied"
echo "PASS: verification"
echo "PASS: security health"
JS
echo

echo "### 8. ORCHESTRATION RUNTIME GATE"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.orchestration.run(
  "full system continuation verification",
  5
)

if (result.cycles !== 5) {
  throw new Error(
    `Expected 5 cycles, got ${result.cycles}`
  )
}

if (!Array.isArray(result.results)) {
  throw new Error("Orchestration results missing")
}

if (result.results.length !== 5) {
  throw new Error(
    `Expected 5 results, got ${result.results.length}`
  )
}

if (!result.best || !(result.best.score > 0)) {
  throw new Error("Best candidate invalid")
}

if (result.status !== "complete") {
  throw new Error("Orchestration incomplete")
}

console.log("PASS: orchestration execution")
console.log(`PASS: cycles=${result.cycles}`)
echo=""

echo "PASS: result count=${result.results.length}"
echo "PASS: best candidate score=${result.best.score}"
JS
echo

echo "### 9. FULL REGRESSION SUITE"
npm test
echo
echo "PASS: full regression suite"
echo

echo "### 10. PRODUCTION BUILD"
npm run build
echo
echo "PASS: production build"
echo

echo "### 11. BUILD ARTIFACT VERIFICATION"

[ -d ".next" ] || {
  echo "FAIL: .next missing"
  exit 1
}

[ -f ".next/server/app-paths-manifest.json" ] || {
  echo "FAIL: app-paths-manifest.json missing"
  exit 1
}

[ -f ".next/server/pages-manifest.json" ] || {
  echo "FAIL: pages-manifest.json missing"
  exit 1
}

echo "PASS: .next exists"
echo "PASS: app-paths-manifest.json"
echo "PASS: pages-manifest.json"
echo

echo "### 12. PACKAGE SCRIPTS"

node --input-type=module <<'JS'
import fs from "node:fs"

const pkg = JSON.parse(
  fs.readFileSync("package.json", "utf8")
)

console.log("Available npm scripts:")

for (const [name, command] of Object.entries(pkg.scripts || {})) {
  console.log(`  ${name}: ${command}`)
}
JS
echo

echo "### 13. GIT RELEASE STATE"

git status --short || true

echo
echo "Changed files:"
git diff --name-only || true

echo
echo "Diff statistics:"
git diff --stat || true

echo
echo "HEAD:"
git rev-parse HEAD

echo
echo "Branch:"
git branch --show-current

echo

echo "### 14. SAVE RELEASE MANIFEST"

cat > "$CHECKPOINT/RELEASE_MANIFEST.txt" <<MANIFEST
OMEGA® RELEASE CHECKPOINT

Timestamp:
$STAMP

Repository:
$ROOT

HEAD:
$(git rev-parse HEAD 2>/dev/null || echo unknown)

Branch:
$(git branch --show-current 2>/dev/null || echo unknown)

Public Contract:
PASS

Agents:
PASS

Security:
PASS

Orchestration:
PASS

Regression:
PASS

Production Build:
PASS

Build Artifacts:
PASS

This checkpoint was created before continuation.
MANIFEST

echo "PASS: release manifest"

echo
echo "============================================================"
echo " OMEGA® FULL PRE-CONTINUATION GATE: PASS"
echo "============================================================"
echo
echo "Checkpoint:"
echo "  $CHECKPOINT"
echo
echo "ALL PRE-CONTINUATION GATES PASSED."
echo
echo "============================================================"
echo " AUTHORIZATION"
echo "============================================================"
echo
echo "OMEGA_CONTINUE is now authorized."
echo
echo "IMPORTANT:"
echo "The continuation command itself is NOT guessed."
echo "The installed project command is inspected above."
echo
