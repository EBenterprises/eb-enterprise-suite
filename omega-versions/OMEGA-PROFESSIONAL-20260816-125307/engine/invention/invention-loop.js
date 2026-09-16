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
