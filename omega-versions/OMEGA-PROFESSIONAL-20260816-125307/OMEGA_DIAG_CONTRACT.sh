#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/omega"
cd "$ROOT" || exit 1

echo "================ OMEGA® CONTRACT DIAGNOSTIC ================"
echo

echo "### 1. PACKAGE"
node - <<'NODE'
const fs=require('fs');
const p=JSON.parse(fs.readFileSync('package.json','utf8'));
console.log(JSON.stringify(p.scripts,null,2));
NODE

echo
echo "### 2. OMEGA CORE EXPORTS"
node --input-type=module - <<'NODE'
import * as O from './src/core/omega.js';
console.log(Object.keys(O).sort().join('\n'));
NODE

echo
echo "### 3. REQUIRED PUBLIC EXPORT REFERENCES"
grep -RhoE '\b(metrics|memory|orchestration|learning|agents|security|governance|verification|planning|telemetry|flow|contracts|scheduler|plugins|observability|OmegaError|fail|required|object)\b' \
  tests src/core 2>/dev/null | sort | uniq -c | sort -nr | head -100

echo
echo "### 4. CORE TREE"
find src/core -maxdepth 3 -type f -print | sort

echo
echo "### 5. TEST CONTRACTS"
for f in \
  tests/contracts/public-api.test.js \
  tests/contracts/integrity.test.js \
  tests/hardening.test.js \
  tests/next.test.js \
  tests/next5.test.js \
  tests/system.test.js
do
  if [ -f "$f" ]; then
    echo
    echo "----- $f -----"
    sed -n '1,220p' "$f"
  fi
done

echo
echo "### 6. CURRENT CORE"
echo "----- src/core/omega.js -----"
sed -n '1,320p' src/core/omega.js

echo
echo "### 7. PACKAGE VALIDATION"
node - <<'NODE'
const fs=require('fs');
const p=JSON.parse(fs.readFileSync('package.json','utf8'));
console.log("start:",JSON.stringify(p.scripts?.start));
console.log("dev:",JSON.stringify(p.scripts?.dev));
console.log("build:",JSON.stringify(p.scripts?.build));
NODE

echo
echo "============================================================"
