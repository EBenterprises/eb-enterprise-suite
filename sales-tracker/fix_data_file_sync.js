const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The bug: In server.js, some places read/write DATA_FILE while the update_tx block was reading/writing TRANSACTIONS_FILE!
// Let's unify TRANSACTIONS_FILE and DATA_FILE so both point to 'transactions.json' and use DATA_FILE everywhere.
code = code.replace(/TRANSACTIONS_FILE/g, 'DATA_FILE');

// Also, let's add console.log statement inside the POST handler for debugging any incoming action & payload
const debugLogBlock = `
            req.on('end', () => {
                try {
                    const parsedBody = JSON.parse(body);
                    const { action, payload } = parsedBody;
                    console.log("[+] Received Action:", action, "Payload:", JSON.stringify(payload));
                    let txs = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
`;

code = code.replace(
    /req\.on\('end',\s*\(\)\s*=>\s*\{\s*try\s*\{\s*const\s*\{\s*action,\s*payload\s*\}\s*=\s*JSON\.parse\(body\);\s*let\s*txs\s*=\s*JSON\.parse\(fs\.readFileSync\(DATA_FILE,\s*'utf8'\)\);\s*\}/s,
    debugLogBlock
);

fs.writeFileSync(serverPath, code);
console.log("[+] Unified data file references to DATA_FILE ('transactions.json') and added action debugging logs.");
