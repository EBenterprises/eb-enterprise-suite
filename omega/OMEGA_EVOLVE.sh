#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

mkdir -p engine/invention inventions .omega/cache .omega/proofs

cat > engine/invention/evolve.js <<'NODE'
import fs from "node:fs";
import crypto from "node:crypto";

const root = process.cwd();
const source = `${root}/inventions/winners.jsonl`;
const candidates = `${root}/inventions/evolved.jsonl`;
const winners = `${root}/inventions/winners.jsonl`;

const generations = Number(process.env.OMEGA_GENERATIONS || 3);
const population = Number(process.env.OMEGA_POPULATION || 32);

if (!fs.existsSync(source)) {
  console.error("No invention population exists.");
  console.error("Run ./OMEGA_FAST.sh first.");
  process.exit(1);
}

function hash(value) {
  return crypto
    .createHash("sha256")
    .update(value)
    .digest("hex")
    .slice(0, 20);
}

function mutate(item, generation, index) {
  const mutations = [
    "compose",
    "invert",
    "compress",
    "expand",
    "parallelize",
    "specialize",
    "generalize",
    "optimize",
    "synthesize",
    "hybridize"
  ];

  const mutation =
    mutations[(generation + index) % mutations.length];

  const operation = `${mutation}(${item.operation})`;

  return {
    id: hash(`${generation}:${index}:${operation}`),
    parent: item.id,
    generation,
    operation,
    objective: item.objective,
    novelty: Math.min(1, Number(item.novelty || 0.5) + 0.05),
    score: Number(
      (
        Number(item.score || 0) +
        mutation.length * 2 +
        generation * 5
      ).toFixed(3)
    ),
    status: "evolved"
  };
}

let populationData = fs
  .readFileSync(source, "utf8")
  .split("\n")
  .filter(Boolean)
  .map(JSON.parse)
  .sort((a, b) => b.score - a.score)
  .slice(0, population);

for (let generation = 1; generation <= generations; generation++) {
  const next = [];

  for (let i = 0; i < populationData.length; i++) {
    next.push(
      mutate(populationData[i], generation, i)
    );
  }

  populationData = next
    .sort((a, b) => b.score - a.score)
    .slice(0, population);

  fs.appendFileSync(
    candidates,
    populationData.map(x => JSON.stringify(x)).join("\n") + "\n"
  );

  console.log(
    `GENERATION ${generation}: ${populationData.length} candidates`
  );
}

fs.appendFileSync(
  winners,
  populationData
    .slice(0, 10)
    .map(x => JSON.stringify({
      ...x,
      status: "winner"
    }))
    .join("\n") + "\n"
);

console.log("");
console.log(JSON.stringify({
  generations,
  population: populationData.length,
  best: populationData[0] ?? null,
  status: "EVOLUTION_COMPLETE"
}, null, 2));
NODE

cat > engine/invention/novelty.js <<'NODE'
import fs from "node:fs";
import crypto from "node:crypto";

const file = "inventions/winners.jsonl";

if (!fs.existsSync(file)) {
  console.log("NO_INVENTIONS");
  process.exit(0);
}

const records = fs.readFileSync(file, "utf8")
  .split("\n")
  .filter(Boolean)
  .map(JSON.parse);

const exact = new Set();
const unique = [];

for (const record of records) {
  const key = crypto
    .createHash("sha256")
    .update(record.operation || "")
    .digest("hex");

  if (exact.has(key)) continue;

  exact.add(key);

  unique.push({
    ...record,
    noveltyVerified: true,
    noveltyHash: key.slice(0, 20)
  });
}

fs.writeFileSync(
  "inventions/novel-winners.jsonl",
  unique.map(x => JSON.stringify(x)).join("\n") + "\n"
);

console.log(JSON.stringify({
  total: records.length,
  unique: unique.length,
  duplicatesRemoved: records.length - unique.length,
  status: "NOVELTY_FILTER_COMPLETE"
}, null, 2));
NODE

cat > engine/invention/constraints.js <<'NODE'
const args = process.argv.slice(2);

const objective =
  args.find(x => x.startsWith("--objective="))
    ?.split("=")
    .slice(1)
    .join("=") || "general improvement";

const constraints = args
  .filter(x => x.startsWith("--constraint="))
  .map(x => x.split("=").slice(1).join("="));

const forbidden = args
  .filter(x => x.startsWith("--forbid="))
  .map(x => x.split("=").slice(1).join("="));

const result = {
  objective,
  constraints,
  forbidden,
  createdAt: new Date().toISOString(),
  status: "CONSTRAINT_GRAPH_READY"
};

console.log(JSON.stringify(result, null, 2));
NODE

cat > OMEGA_EVOLVE.sh <<'EOF2'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

GENERATIONS="${OMEGA_GENERATIONS:-5}"
POPULATION="${OMEGA_POPULATION:-32}"

echo
echo "============================================================"
echo "OMEGA® — RAPID EVOLUTION ENGINE"
echo "============================================================"
echo
echo "Generations : $GENERATIONS"
echo "Population  : $POPULATION"
echo

OMEGA_GENERATIONS="$GENERATIONS" \
OMEGA_POPULATION="$POPULATION" \
node engine/invention/evolve.js

echo
node engine/invention/novelty.js

echo
echo "============================================================"
echo "OMEGA® — EVOLUTION COMPLETE"
echo "============================================================"
echo
echo "Novel winners:"
tail -10 inventions/novel-winners.jsonl 2>/dev/null || true
echo
EOF2

cat > OMEGA_INVENT_ALL.sh <<'EOF2'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

OBJECTIVE="${*:-invent a superior solution}"

echo
echo "============================================================"
echo "OMEGA® — INVENT → EVOLVE → FILTER"
echo "============================================================"
echo

./OMEGA_FAST.sh "$OBJECTIVE"

echo
./OMEGA_EVOLVE.sh

echo
echo "============================================================"
echo "OMEGA® — RAPID INVENTION COMPLETE"
echo "============================================================"
echo
echo "Objective:"
echo "$OBJECTIVE"
echo
echo "Output:"
echo "  inventions/candidates.jsonl"
echo "  inventions/winners.jsonl"
echo "  inventions/evolved.jsonl"
echo "  inventions/novel-winners.jsonl"
echo
echo "FULL CERTIFICATION NOT RUN."
echo "============================================================"
EOF2

chmod +x OMEGA_EVOLVE.sh
chmod +x OMEGA_INVENT_ALL.sh

node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
p.scripts=p.scripts||{};
p.scripts["evolve"]="bash OMEGA_EVOLVE.sh";
p.scripts["invent:all"]="bash OMEGA_INVENT_ALL.sh";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
'

echo
echo "OMEGA® RAPID INVENTION EXTENSION INSTALLED"
echo
echo "Run:"
echo
echo '  ./OMEGA_INVENT_ALL.sh "your objective"'
echo
echo "Or:"
echo '  ./OMEGA_FAST.sh "your objective"'
echo "  ./OMEGA_EVOLVE.sh"
echo
echo "No production build is performed during invention."
echo "No certification is claimed."
