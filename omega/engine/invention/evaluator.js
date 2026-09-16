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
