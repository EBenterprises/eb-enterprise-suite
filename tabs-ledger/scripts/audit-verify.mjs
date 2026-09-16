import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { verifyAuditChain } = require("../lib/services/audit.ts");

const result = verifyAuditChain();

console.log(JSON.stringify(result, null, 2));

if (!result.ok) {
  process.exitCode = 1;
}
