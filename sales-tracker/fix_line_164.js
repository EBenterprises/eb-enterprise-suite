const fs = require('fs');
const path = require('path');
const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Clean up mismatched parentheses or unterminated function/try blocks around line 164
code = code.replace(/\}\s*\);\s*\}\s*\n\s*\}/g, '}\n});');
code = code.replace(/catch\s*\([^)]*\)\s*\{\}\s*\)\s*;/g, 'catch(e) {}');

fs.writeFileSync(serverPath, code);
console.log("[+] Line 164 syntax cleaned!");
