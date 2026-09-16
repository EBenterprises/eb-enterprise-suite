import { reconcileLedger } from "../lib/services/reconciliation.ts";

const result = reconcileLedger();

console.log(JSON.stringify(result, null, 2));

if (!result.ok) {
  process.exitCode = 1;
}
