const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Fix the corrupted destructuring line around line 108
code = code.replace(/const\s+\{\s*action,\s*payload\s*\}\s*catch\(e\)\s*\{\}\s*=\s*/g, 'const { action, payload } = ');
code = code.replace(/const\s+\{\s*action,\s*payload\s*\}\s*catch\(e\)\s*\{\}\s*/g, 'const { action, payload } = JSON.parse(body || "{}");');

fs.writeFileSync(serverPath, code);
console.log("[+] Destructuring syntax fixed!");
