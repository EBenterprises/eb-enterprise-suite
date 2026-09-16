#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TARGET="$ROOT/src/core/public-contract.js"

echo "============================================================"
echo " OMEGA® FINAL VERIFICATION + RELEASE GATE"
echo "============================================================"

echo
echo "### 1. SOURCE SYNTAX"
node --check "$TARGET"
echo "PASS: public-contract.js"

echo
echo "### 2. AUTONOMY CONTRACT GATE"
./OMEGA_AUTONOMY_CONTRACT_GATE.sh

echo
echo "### 3. FULL TEST SUITE"
npm test

echo
echo "### 4. PRODUCTION BUILD"
npm run build

echo
echo "### 5. BUILD ARTIFACTS"

for path in \
  ".next/server" \
  ".next/app-build-manifest.json" \
  ".next/server/app-paths-manifest.json" \
  ".next/server/pages-manifest.json"
do
  if [ ! -e "$path" ]; then
    echo "FAIL: missing $path"
    exit 1
  fi

  echo "PASS: $path"
done

echo
echo "### 6. PUBLIC CONTRACT INVENTORY"

grep -nE \
  '^export const (metrics|memory|scheduler|plugins|contracts|observability|governance|verification|planning|telemetry|flow|orchestration|learning|agents|security|registryApi)' \
  "$TARGET"

echo
echo "### 7. AUTONOMY MARKERS"

grep -nE \
  'async run|async agent|agentStore|DENIED_ACTION_PATTERNS|ACTION_DENIED|ACTION_ALLOWED' \
  "$TARGET"

echo
echo "### 8. GIT STATE"

git status --short

echo
echo "### 9. RELEASE SNAPSHOT"

git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD

echo
echo "============================================================"
echo " OMEGA® FINAL VERIFICATION: PASS"
echo "============================================================"
echo
echo "ALL GATES PASSED."
echo
echo "NEXT STAGE:"
echo "  OMEGA® CONTINUOUS EXECUTION / ADVANCEMENT"
echo
