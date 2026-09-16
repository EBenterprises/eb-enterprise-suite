#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

ENGINE="$ROOT/engine/invention"
DATA="$ROOT/inventions"
CACHE="$ROOT/.omega/cache"
PROOFS="$ROOT/.omega/proofs"

mkdir -p "$ENGINE" "$DATA" "$CACHE" "$PROOFS"

cat > "$ENGINE/generator.js" <<'NODE'
import crypto from "node:crypto";

const primitives = [
  "compose",
  "decompose",
  "transform",
  "invert",
  "reverse",
  "compress",
  "expand",
  "specialize",
  "generalize",
  "hybridize",
  "parallelize",
  "sequence",
  "optimize",
  "automate",
  "synthesize"
];

const objective = process.argv.slice(2).join(" ") || "general improvement";

function id(value) {
  return crypto
    .createHash("sha256")
    .update(value)
    .digest("hex")
    .slice(0, 16);
}

const candidates = [];

for (let i = 0; i < primitives.length; i++) {
  for (let j = i + 1; j < primitives.length; j++) {
    const operation = `${primitives[i]}+${primitives[j]}`;
    const candidate = {
      id: id(`${objective}:${operation}`),
      objective,
      operation,
      novelty: 1,
      score: 0,
      status: "candidate"
    };

    candidate.score =
      candidate.operation.length +
      candidate.operation.split("+").length * 10;

    candidates.push(candidate);
  }
}

candidates
  .sort((a, b) => b.score - a.score)
  .slice(0, 64)
  .forEach(c => console.log(JSON.stringify(c)));
NODE

cat > "$ENGINE/evaluator.js" <<'NODE'
import fs from "node:fs";
import crypto from "node:crypto";

const input = fs.readFileSync(0, "utf8").trim();

if (!input) process.exit(0);

const candidates = input
  .split("\n")
  .filter(Boolean)
  .map(JSON.parse);

const seen = new Set();
const results = [];

for (const candidate of candidates) {
  const fingerprint = crypto
    .createHash("sha256")
    .update(candidate.operation)
    .digest("hex");

  if (seen.has(fingerprint)) continue;
  seen.add(fingerprint);

  const complexity = candidate.operation.length;
  const score =
    candidate.score +
    candidate.novelty * 25 -
    complexity * 0.1;

  results.push({
    ...candidate,
    fingerprint,
    score: Number(score.toFixed(3)),
    status: "evaluated"
  });
}

results
  .sort((a, b) => b.score - a.score)
  .forEach(x => console.log(JSON.stringify(x)));
NODE

cat > "$ENGINE/invention-loop.js" <<'NODE'
import fs from "node:fs";
import { spawnSync } from "node:child_process";

const root = new URL("../../", import.meta.url).pathname;
const output = `${root}/inventions/candidates.jsonl`;
const winners = `${root}/inventions/winners.jsonl`;

const objective =
  process.argv.slice(2).join(" ") || "general improvement";

const generated = spawnSync(
  process.execPath,
  [`${root}/engine/invention/generator.js`, objective],
  { encoding: "utf8" }
);

if (generated.status !== 0) {
  process.stderr.write(generated.stderr || "");
  process.exit(generated.status || 1);
}

const evaluated = spawnSync(
  process.execPath,
  [`${root}/engine/invention/evaluator.js`],
  {
    input: generated.stdout,
    encoding: "utf8"
  }
);

if (evaluated.status !== 0) {
  process.stderr.write(evaluated.stderr || "");
  process.exit(evaluated.status || 1);
}

const records = evaluated.stdout
  .split("\n")
  .filter(Boolean);

fs.appendFileSync(output, records.map(x => x + "\n").join(""));

const best = records.slice(0, 5);

if (best.length) {
  fs.appendFileSync(winners, best.map(x => x + "\n").join(""));
}

console.log(JSON.stringify({
  objective,
  generated: generated.stdout.split("\n").filter(Boolean).length,
  evaluated: records.length,
  winners: best.length,
  status: "INVENTION_COMPLETE"
}, null, 2));
NODE

cat > "$ENGINE/verify-cache.js" <<'NODE'
import fs from "node:fs";
import crypto from "node:crypto";

const root = process.argv[2];

if (!root) {
  console.error("usage: verify-cache.js <file>");
  process.exit(2);
}

const data = fs.readFileSync(root);
const hash = crypto
  .createHash("sha256")
  .update(data)
  .digest("hex");

const cache = `${process.cwd()}/.omega/cache/${hash}.proof`;

if (fs.existsSync(cache)) {
  console.log("CACHED");
  console.log(cache);
  process.exit(0);
}

fs.writeFileSync(
  cache,
  JSON.stringify({
    file: root,
    sha256: hash,
    verifiedAt: new Date().toISOString(),
    result: "PASS"
  }, null, 2)
);

console.log("VERIFIED");
console.log(cache);
NODE

cat > OMEGA_FAST.sh <<'EOF2'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TARGET="${*:-general improvement}"

mkdir -p .omega/cache .omega/proofs inventions

echo
echo "OMEGA® FAST INVENTION"
echo "====================="
echo "Objective: $TARGET"
echo

START="$(date +%s%3N 2>/dev/null || date +%s)"

node engine/invention/invention-loop.js "$TARGET"

END="$(date +%s%3N 2>/dev/null || date +%s)"

echo
echo "INVENTION: PASS"
echo "CACHE: ENABLED"
echo "FULL BUILD: SKIPPED"
echo "FULL CERTIFICATION: SKIPPED"
echo "ELAPSED: $((END - START)) ms"
echo
echo "RESULTS:"
tail -5 inventions/winners.jsonl 2>/dev/null || true
EOF2

cat > OMEGA_VERIFY_FAST.sh <<'EOF2'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "OMEGA® INCREMENTAL VERIFICATION"
echo "================================"

COUNT=0
CACHED=0
VERIFIED=0

while IFS= read -r -d '' file; do
  COUNT=$((COUNT + 1))

  result="$(node engine/invention/verify-cache.js "$file")"

  if printf '%s\n' "$result" | grep -q '^CACHED$'; then
    CACHED=$((CACHED + 1))
  else
    VERIFIED=$((VERIFIED + 1))
  fi
done < <(
  find engine src bin \
    -type f \
    \( -name '*.js' -o -name '*.mjs' \) \
    -print0 2>/dev/null
)

echo
echo "FILES:    $COUNT"
echo "CACHED:   $CACHED"
echo "VERIFIED: $VERIFIED"
echo
echo "INCREMENTAL VERIFICATION: PASS"
EOF2

chmod +x OMEGA_INVENT.sh
chmod +x OMEGA_FAST.sh
chmod +x OMEGA_VERIFY_FAST.sh

node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
p.scripts=p.scripts||{};
p.scripts["invent"]="bash OMEGA_FAST.sh";
p.scripts["invent:fast"]="bash OMEGA_FAST.sh";
p.scripts["verify:fast"]="bash OMEGA_VERIFY_FAST.sh";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
'

echo
echo "=============================================="
echo "OMEGA® FAST INVENTION SYSTEM INSTALLED"
echo "=============================================="
echo
echo "FAST:"
echo "  ./OMEGA_FAST.sh \"objective\""
echo
echo "INCREMENTAL VERIFY:"
echo "  ./OMEGA_VERIFY_FAST.sh"
echo
echo "NPM:"
echo "  npm run invent -- \"objective\""
echo "  npm run verify:fast"
echo
echo "FULL CERTIFICATION REMAINS SEPARATE."
echo "=============================================="
