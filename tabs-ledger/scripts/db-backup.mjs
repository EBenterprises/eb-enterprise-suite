import { createVerifiedBackup } from "../lib/services/backup.ts";

const result = createVerifiedBackup();

console.log(JSON.stringify(result, null, 2));
