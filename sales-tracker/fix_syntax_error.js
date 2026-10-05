const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Fix the template string scope error by safely referencing the correct template variable or hardcoding string concatenation properly
code = code.replace(
    /\$\{t\.id\}/g,
    "' + t.id + '"
);

code = code.replace(
    /\$\{t\.date\}/g,
    "' + (t.date ? t.date.replace(' ', 'T') : '') + '"
);

fs.writeFileSync(serverPath, code, 'utf8');
console.log("[+] Syntax fixed for template literal injection!");
