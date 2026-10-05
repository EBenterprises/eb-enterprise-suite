const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
const backupDir = path.join(__dirname, 'backups_end_state');
if (fs.existsSync(backupDir)) {
    const backupFiles = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
    backupFiles.sort();
    if (backupFiles.length > 0) {
        fs.copyFileSync(path.join(backupDir, backupFiles[backupFiles.length - 1]), serverPath);
        console.log("[+] Restored server.js from clean end-state backup.");
    }
}

let code = fs.readFileSync(serverPath, 'utf8');

// Ensure v5 title & badge are correct
code = code.replace(
    /titles\['v4'\]\s*=\s*'[^']*';/,
    "titles['v4'] = 'Enterprise P2P Master Suite v4';\n    titles['v5'] = 'Enterprise P2P Master Suite v5 - History & Time Travel';"
);
code = code.replace(
    /badges\['v4'\]\s*=\s*'[^']*';/,
    "badges['v4'] = '📍 v4 UI';\n    badges['v5'] = '⏳ v5 Time Travel';"
);
code = code.replace(/if\s*\(\s*version\s*===\s*'v4'\s*\)/g, "if (version === 'v4' || version === 'v5')");

// Fix transaction update and add/edit logic so running balances are calculated properly per customer chronologically
// Let's add a helper function or logic to recalculate all transaction balances chronologically whenever transactions are added or updated.
const balanceRecalcLogic = `
function recalculateRunningBalances(transactions) {
    const sorted = [...transactions].sort((a, b) => (a.timestamp || 0) - (b.timestamp || 0));
    const customerTotals = {};
    sorted.forEach(t => {
        const cust = (t.customer || '').trim().toLowerCase();
        if (!cust) return;
        const amt = Number(t.amount) || 0;
        const cash = Number(t.cashCollected) || 0;
        customerTotals[cust] = (customerTotals[cust] || 0) + amt - cash;
        t.balance = customerTotals[cust];
    });
    return sorted;
}
`;

// Inject balance recalc into server helper functions
code = balanceRecalcLogic + "\n" + code;

// Update add_sale and update_tx to run recalculateRunningBalances before saving to DATA_FILE
code = code.replace(
    /fs\.writeFileSync\(DATA_FILE,\s*JSON\.stringify\(txs,\s*null,\s*2\)\);/g,
    `txs = recalculateRunningBalances(txs);\n            fs.writeFileSync(DATA_FILE, JSON.stringify(txs, null, 2));`
);

// Also unify TRANSACTIONS_FILE to DATA_FILE
code = code.replace(/TRANSACTIONS_FILE/g, 'DATA_FILE');

// Add port 51205 listener
const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History & Time Travel Suite) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;

code = code.replace(
    /http\.createServer\(createAppHandler\('v4'\)\)\.listen\(PORT_V4,\s*[^)]+\);/,
    match => match + "\n" + portV5Block
);

fs.writeFileSync(serverPath, code);
console.log("[+] Successfully restored and applied correct chronological customer running balance calculation.");
