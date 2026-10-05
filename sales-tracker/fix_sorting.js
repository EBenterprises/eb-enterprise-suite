const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure transactions are sorted descending by timestamp/id so newest/most recent are on top
if (!serverCode.includes("sort((a, b) => b.timestamp - a.timestamp)")) {
    // Look for where transactions are loaded or processed before rendering/sending
    serverCode = serverCode.replace(
        `let txs = readJson('transactions.json');`,
        `let txs = readJson('transactions.json');\n    txs.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));`
    );
    
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully updated server.js with chronological sorting (newest on top)!");
} else {
    console.log("[!] Chronological sorting already present.");
}
