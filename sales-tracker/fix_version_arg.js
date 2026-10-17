const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Replace function declaration to accept version or default to 'v4'
serverCode = serverCode.replace(
    'function createAppHandlerV5() {',
    'function createAppHandlerV5() {\n    const version = \'v4\';'
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Version variable bound successfully!");
