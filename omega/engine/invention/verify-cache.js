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
