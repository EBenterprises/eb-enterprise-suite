#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

FILE="api/domain-service.js"
BACKUP="$FILE.pre-step10b-repair"

cp "$FILE" "$BACKUP"

echo "=== REQUEST RUNNER® — STEP 10B REPAIR ==="
echo

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let s = fs.readFileSync(file, "utf8");
const lines = s.split("\n");

let hits = [];
for (let i = 0; i < lines.length; i++) {
  if (/\bconst\s+current\s*=/.test(lines[i]) ||
      /\blet\s+current\s*=/.test(lines[i])) {
    hits.push(i + 1);
  }
}

if (hits.length < 2) {
  throw new Error("Could not identify duplicate current declarations");
}

const target = hits[1] - 1;
lines[target] = lines[target]
  .replace(/\bconst\s+current\s*=/, "const orderCurrent =")
  .replace(/\blet\s+current\s*=/, "let orderCurrent =");

fs.writeFileSync(file, lines.join("\n"));

console.log(`Repaired declaration at line ${target + 1}`);
NODE

echo
echo "[1] SYNTAX"
node --check api/domain-service.js
echo "✓"

echo
echo "[2] STEP 10B"
chmod 700 STEP10B_WIRE_CANONICAL_LIFECYCLE.sh
./STEP10B_WIRE_CANONICAL_LIFECYCLE.sh >/dev/null
echo "✓"

rm -f "$BACKUP"

clear
echo "=== STEP 10B REPAIR ==="
echo
echo "✓ DOMAIN SERVICE"
echo "✓ SYNTAX"
echo "✓ STEP 10B"
echo
echo "RESUME BUILD:"
echo "./RUNNER_RESUME.sh"
