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
