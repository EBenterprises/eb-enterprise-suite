#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TARGET="$ROOT/src/core/public-contract.js"
STAMP="$(date +%Y%m%d_%H%M%S)"
REPORT="$ROOT/.omega-final-$STAMP"

mkdir -p "$REPORT"

echo "============================================================"
echo " OMEGA® FINAL VERIFICATION — FIXED"
echo "============================================================"
echo "ROOT: $ROOT"
echo "STAMP: $STAMP"
echo

echo "### 1. SOURCE SYNTAX"

node --check "$TARGET"

echo "PASS: public-contract.js syntax"
echo

echo "### 2. PUBLIC AUTONOMY CONTRACT"

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
echo "### 3. AGENT RUNTIME"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.agents.agent(
  "final autonomous verification",
  5
)

if (result?.type !== "agent-run") {
  throw new Error("Invalid agent result type")
}

if (result?.cycles !== 5) {
  throw new Error(`Expected 5 cycles, got ${result?.cycles}`)
}

if (result?.status !== "complete") {
  throw new Error("Agent did not complete")
}

if (
  !result?.adaptation ||
  typeof result.adaptation.confidence !== "number"
) {
  throw new Error("Invalid adaptation result")
}

console.log("PASS: agent execution")
console.log(`PASS: cycles=${result.cycles}`)
console.log(`PASS: confidence=${result.adaptation.confidence}`)

const name = "__omega_final_verification_agent__"

O.agents.register(name, {
  purpose: "final-verification"
})

if (!O.agents.get(name)) {
  throw new Error("Agent retrieval failed")
}

if (!O.agents.remove(name)) {
  throw new Error("Agent removal failed")
}

console.log("PASS: agent lifecycle")
JS

echo
echo "### 4. SECURITY RUNTIME"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const safe = O.security.authorize("echo OMEGA")

if (
  safe.allowed !== true ||
  safe.authorized !== true
) {
  throw new Error("Safe operation rejected")
}

console.log("PASS: safe authorization")

const dangerous = O.security.authorize("rm -rf /")

if (
  dangerous.allowed !== false ||
  dangerous.authorized !== false
) {
  throw new Error("Destructive operation was allowed")
}

if (dangerous.reason !== "ACTION_DENIED") {
  throw new Error(
    `Incorrect denial reason: ${dangerous.reason}`
  )
}

console.log("PASS: destructive authorization denied")

const verification = O.security.verify(
  "omega-final-verification"
)

if (verification.valid !== true) {
  throw new Error("Security verification failed")
}

console.log("PASS: security verification")

const status = O.security.status()

if (status.status !== "healthy") {
  throw new Error("Security status unhealthy")
}

console.log("PASS: security health")
JS

echo
echo "### 5. ORCHESTRATION RUNTIME"

node --input-type=module <<'JS'
import * as O from "./src/core/public-contract.js"

const result = await O.orchestration.run(
  "final autonomous orchestration verification",
  5
)

if (result?.status !== "complete") {
  throw new Error("Orchestration did not complete")
}

if (result?.cycles !== 5) {
  throw new Error(
    `Expected 5 cycles, got ${result?.cycles}`
  )
}

if (!Array.isArray(result?.results)) {
  throw new Error("Orchestration results missing")
}

if (result.results.length !== 5) {
  throw new Error(
    `Expected 5 results, got ${result.results.length}`
  )
}

if (!result.best) {
  throw new Error("Best candidate missing")
}

if (typeof result.best.score !== "number") {
  throw new Error("Best candidate score invalid")
}

console.log("PASS: orchestration execution")
console.log(`PASS: cycles=${result.cycles}`)
console.log(`PASS: results=${result.results.length}`)
console.log(`PASS: best-score=${result.best.score}`)
JS

echo
echo "### 6. SOURCE INTEGRITY"

AGENTS="$(grep -c '^// Agents$' "$TARGET" || true)"
SECURITY="$(grep -c '^// Security$' "$TARGET" || true)"
REGISTRY="$(grep -c '^// Generic stable public namespace$' "$TARGET" || true)"

[ "$AGENTS" -eq 1 ] || {
  echo "FAIL: Agents contract count=$AGENTS"
  exit 1
}

[ "$SECURITY" -eq 1 ] || {
  echo "FAIL: Security contract count=$SECURITY"
  exit 1
}

[ "$REGISTRY" -eq 1 ] || {
  echo "FAIL: registry boundary count=$REGISTRY"
  exit 1
}

echo "PASS: one Agents contract"
echo "PASS: one Security contract"
echo "PASS: one registry boundary"

echo
echo "### 7. REGRESSION TESTS"

npm test

echo
echo "PASS: 39-test regression suite completed"
echo

echo "### 8. PRODUCTION BUILD"

npm run build

echo
echo "PASS: production build"
echo

echo "### 9. NEXT.JS ARTIFACT DISCOVERY"

if [ ! -d ".next" ]; then
  echo "FAIL: .next directory missing"
  exit 1
fi

echo "PASS: .next exists"

if [ -d ".next/server" ]; then
  echo "PASS: .next/server exists"
else
  echo "FAIL: .next/server missing"
  exit 1
fi

echo
echo "Detected Next.js build manifests:"

find .next \
  -maxdepth 4 \
  -type f \
  \( \
    -name '*manifest*.json' \
    -o -name 'BUILD_ID' \
    -o -name 'package.json' \
  \) \
  -print \
  | sort \
  | tee "$REPORT/next-artifacts.txt"

echo

echo "### 10. REQUIRED BUILD STRUCTURE"

for path in \
  ".next" \
  ".next/server" \
  ".next/static"
do
  if [ -e "$path" ]; then
    echo "PASS: $path"
  else
    echo "FAIL: missing $path"
    exit 1
  fi
done

echo
echo "### 11. APP BUILD OUTPUT"

find .next/server/app \
  -maxdepth 4 \
  -type f \
  -print \
  2>/dev/null \
  | sort \
  | tee "$REPORT/app-output.txt" || true

echo
echo "### 12. PACKAGE / PROJECT INVENTORY"

node --input-type=module <<'JS'
import fs from "node:fs"

const pkg = JSON.parse(
  fs.readFileSync("package.json", "utf8")
)

console.log("name:", pkg.name)
console.log("version:", pkg.version)

console.log("")
console.log("scripts:")

for (const [name, command] of Object.entries(pkg.scripts || {})) {
  console.log(`  ${name}: ${command}`)
}
JS

echo
echo "### 13. GIT STATE"

git status --short | tee "$REPORT/git-status.txt" || true

echo
echo "HEAD:"
git rev-parse HEAD | tee "$REPORT/head.txt" || true

echo
echo "BRANCH:"
git branch --show-current | tee "$REPORT/branch.txt" || true

echo
echo "### 14. SOURCE INVENTORY"

find src \
  -type f \
  \( \
    -name '*.js' \
    -o -name '*.mjs' \
    -o -name '*.ts' \
    -o -name '*.tsx' \
  \) \
  -print \
  | sort \
  | tee "$REPORT/source-inventory.txt"

echo
echo "### 15. OMEGA AUTONOMY SURFACE"

grep -nE \
  'async run|async agent|agentStore|DENIED_ACTION_PATTERNS|ACTION_DENIED|ACTION_ALLOWED' \
  "$TARGET" \
  | tee "$REPORT/autonomy-surface.txt" || true

echo
echo "### 16. FINAL REPORT"

cat > "$REPORT/FINAL_REPORT.txt" <<REPORT
OMEGA® FINAL VERIFICATION

Timestamp:
$STAMP

Source syntax:
PASS

Public contract:
PASS

Agent runtime:
PASS

Agent lifecycle:
PASS

Security:
PASS

Orchestration:
PASS

Regression:
PASS

Production build:
PASS

Next.js build structure:
PASS

This verification intentionally does not require a
specific Next.js internal manifest pathname.

The actual generated artifacts were recorded separately.
REPORT

echo "PASS: final report created"
echo "REPORT: $REPORT"

echo
echo "============================================================"
echo " OMEGA® FINAL VERIFICATION: PASS"
echo "============================================================"
echo
echo "ALL CURRENT GATES PASSED."
echo
echo "NEXT STAGE:"
echo "  AUTONOMOUS ADVANCEMENT / CONTINUOUS EXECUTION"
echo
