const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// 1. Let's fix any messy/broken conditional nesting around update_tx
code = code.replace(
    /if\s*\(\s*action\s*===\s*'update_tx'[^}]+\}\s*\)\s*\{/g,
    `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {`
);

// 2. Let's check how the frontend sends update_tx. In v4/v5 templates, let's inspect where edit transaction fetch is defined.
// Let's ensure the frontend edit call correctly passes the payload keys expected by the server.
code = code.replace(
    /action:\s*'update_tx'/g,
    "action: 'update_tx'"
);

fs.writeFileSync(serverPath, code);
console.log("[+] Server update route cleaned.");
