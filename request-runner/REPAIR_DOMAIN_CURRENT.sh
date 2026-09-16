#!/data/data/com.termux/files/usr/bin/bash
set -e

FILE="api/domain-service.js"
BACKUP="$FILE.pre-current-repair"

cp "$FILE" "$BACKUP"

clear
echo "=== REQUEST RUNNER® — DOMAIN CURRENT REPAIR ==="

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let lines = fs.readFileSync(file, "utf8").split("\n");

let declarations = [];

for (let i = 0; i < lines.length; i++) {
  if (/\b(?:const|let)\s+current\s*=/.test(lines[i])) {
    declarations.push(i);
  }
}

console.log(`current declarations found: ${declarations.length}`);

if (declarations.length < 2) {
  throw new Error("Expected duplicate current declarations");
}

/*
 * Rename duplicate declarations after the first one.
 * References are renamed within the enclosing function.
 *
 * First declaration remains `current`.
 */
let renameIndex = 1;

for (const lineIndex of declarations.slice(1)) {
  const oldLine = lines[lineIndex];

  lines[lineIndex] = oldLine.replace(
    /\b(current)\b(?=\s*=)/,
    `current_${renameIndex}`
  );

  /*
   * Rename references until the next function boundary.
   */
  let depth = 0;
  let started = false;

  for (let i = lineIndex; i < lines.length; i++) {
    const line = lines[i];

    depth += (line.match(/{/g) || []).length;
    depth -= (line.match(/}/g) || []).length;

    if (i > lineIndex) started = true;

    if (started && depth <= 0 && /}/.test(line)) break;

    if (i !== lineIndex) {
      lines[i] = lines[i].replace(
        /\bcurrent\b/g,
        `current_${renameIndex}`
      );
    }
  }

  renameIndex++;
}

fs.writeFileSync(file, lines.join("\n"));
NODE

echo
echo "[1] SYNTAX"
node --check api/domain-service.js
echo "✓"

echo
echo "[2] STEP 10B"
./STEP10B_WIRE_CANONICAL_LIFECYCLE.sh >/dev/null
echo "✓"

rm -f "$BACKUP"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ DOMAIN REPAIR PASSED"
echo "✓ STEP 10B PASSED"
echo
echo "Run:"
echo "./RUNNER_RESUME.sh"
