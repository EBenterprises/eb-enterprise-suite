#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "============================================================"
echo "              OMEGA® INITIALIZATION"
echo "============================================================"

# ------------------------------------------------------------
# 1. Core workspace
# ------------------------------------------------------------

mkdir -p \
  "$ROOT/.omega/tmp" \
  "$ROOT/.omega/certification" \
  "$ROOT/.omega/logs" \
  "$ROOT/.omega/state"

chmod 700 "$ROOT/.omega"
chmod 700 "$ROOT/.omega/tmp"

# ------------------------------------------------------------
# 2. Initialize Git
# ------------------------------------------------------------

if [ ! -d "$ROOT/.git" ]; then
    git init
    echo "PASS  Git repository initialized"
else
    echo "PASS  Git repository already initialized"
fi

# ------------------------------------------------------------
# 3. Identity
# ------------------------------------------------------------

node - <<'NODE'
const fs = require("fs");

const file = "data/omega-state.json";

let state = {};
try {
  state = JSON.parse(fs.readFileSync(file, "utf8"));
} catch {
  state = {};
}

state.identity ??= {};
state.identity.name = "OMEGA";
state.identity.status = "operational";
state.identity.initialized = true;
state.identity.initializedAt = new Date().toISOString();

fs.writeFileSync(file, JSON.stringify(state, null, 2) + "\n");
NODE

echo "PASS  OMEGA identity initialized"

# ------------------------------------------------------------
# 4. Certification baseline
# ------------------------------------------------------------

cat > .omega/certification/baseline.json <<JSON
{
  "system": "OMEGA®",
  "version": "1.0.0",
  "platform": "android/arm64",
  "buildEngine": "webpack",
  "node": "$(node --version)",
  "npm": "$(npm --version)",
  "initialized": true,
  "initializedAt": "$(date -Iseconds)"
}
JSON

echo "PASS  Certification baseline created"

# ------------------------------------------------------------
# 5. Verify CLI
# ------------------------------------------------------------

echo
echo "=== CLI INITIALIZATION ==="

node bin/omega.js status
node bin/omega.js capabilities
node bin/omega.js metrics

echo "PASS  CLI operational"

# ------------------------------------------------------------
# 6. Verify tests
# ------------------------------------------------------------

echo
echo "=== TEST INITIALIZATION ==="

npm test

echo "PASS  Test suite operational"

# ------------------------------------------------------------
# 7. Verify production build
# ------------------------------------------------------------

echo
echo "=== PRODUCTION INITIALIZATION ==="

npm run build

echo "PASS  Production build operational"

# ------------------------------------------------------------
# 8. Capture Git baseline
# ------------------------------------------------------------

git add -A

if ! git diff --cached --quiet; then
    git commit -m "Initialize OMEGA® certification baseline"
    echo "PASS  Initial Git baseline committed"
else
    echo "PASS  Git baseline already clean"
fi

# ------------------------------------------------------------
# 9. Final state
# ------------------------------------------------------------

echo
echo "============================================================"
echo "             OMEGA® INITIALIZATION COMPLETE"
echo "============================================================"

echo
echo "SYSTEM:"
node bin/omega.js status

echo
echo "GIT:"
git status --short --branch

echo
echo "BUILD:"
grep -n '"build"' package.json

echo
echo "CERTIFICATION BASELINE:"
cat .omega/certification/baseline.json

echo
echo "============================================================"
echo "             OMEGA® IS INITIALIZED"
echo "============================================================"
