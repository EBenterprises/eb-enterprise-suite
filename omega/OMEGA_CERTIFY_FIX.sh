#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"

echo "============================================================"
echo "       OMEGA® GATE 14 — WEBPACK INVOCATION REPAIR"
echo "============================================================"

# Back up the current gate before modification.
cp "$GATE" "$ROOT/.omega/OMEGA_VERIFICATION_GATE.pre-gate14.sh"

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * The gate previously used an invocation equivalent to:
 *
 *   npm exec next build --webpack
 *
 * npm exec interprets --webpack as an npm/project argument in this
 * context, resulting in Next receiving "--webpack" as its project
 * directory.
 *
 * Use the package script instead. package.json already contains:
 *
 *   "build": "next build --webpack"
 *
 * This is the exact command already proven successful on this device.
 */

s = s.replace(
  /npm exec next build\s+(?:--\s+)?--webpack/g,
  "npm run build"
);

/*
 * Also repair any plain npm-exec Next build invocation used by Gate 14.
 */
s = s.replace(
  /npm exec next build(?![^\n]*--webpack)/g,
  "npm run build"
);

/*
 * Normalize accidental duplicate replacements.
 */
s = s.replace(
  /npm run build(?:\s*>\s*\.omega\/tmp\/omega-next-build\.txt)?\s*>\s*\.omega\/tmp\/omega-next-build\.txt/g,
  "npm run build > .omega/tmp/omega-next-build.txt"
);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "=== GATE 14 COMMAND AUDIT ==="
grep -n -A12 -B5 "GATE 14" "$GATE" || true

echo
echo "=== NEXT BUILD INVOCATIONS ==="
grep -nE 'npm exec next build|npm run build|next build' "$GATE" || true

echo
echo "=== SHELL SYNTAX ==="
bash -n "$GATE"
echo "PASS  verification gate syntax"

echo
echo "=== DIRECT BUILD CONFIRMATION ==="
npm run build

echo
echo "============================================================"
echo "       GATE 14 REPAIR COMPLETE"
echo "============================================================"
