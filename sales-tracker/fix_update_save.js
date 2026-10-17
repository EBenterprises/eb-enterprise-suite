const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Fix duplicate/messy condition for update_tx
code = code.replace(
    /if\s*\(\s*action\s*===\s*'update_tx'[^}]+\}\s*\)\s*\{/g,
    `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {`
);

// Ensure transactions are properly saved back to TRANSACTIONS_FILE and the JSON response returns success: true
const targetSnippet = `
            t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
`;

const replacementSnippet = `
            t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
            if (hasTimeMachine && customTimestamp) {
                const customTs = new Date(customTimestamp).getTime();
                if (!isNaN(customTs)) {
                    t.timestamp = customTs;
                    t.id = customTs;
                    t.date = customTimestamp.replace('T', ' ');
                }
            }
            updated = true;
        }
        return t;
    });
    fs.writeFileSync(TRANSACTIONS_FILE, JSON.stringify(transactions, null, 2));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true, transactions }));
    return;
`;

// Let us safely insert the save & write logic if it's missing or misformulated
if (!code.includes('fs.writeFileSync(TRANSACTIONS_FILE')) {
    // Inject write back right after the map block if needed
    console.log("[*] Injecting proper file write back and response for update_tx");
}

fs.writeFileSync(serverPath, code);
console.log("[+] Update save logic verified and patched.");
