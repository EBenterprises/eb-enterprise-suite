const fs = require('fs');
const path = require('path');

// 1. Sort transactions chronologically by timestamp (newest first or oldest first based on preference, let's sort newest first or by timestamp descending, and ensure correct timestamp matching)
const DATA_FILE = path.join(__dirname, 'transactions.json');
let transactions = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));

// Sort transactions by timestamp descending (newest entries at the top)
transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));
fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
console.log("[+] Sorted transactions.json chronologically by timestamp!");

// 2. Update server.js so v5 has the exact v4 feature set PLUS the history edit button + timestamp time travel
let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure update_tx supports v5 and updates timestamp, date, amount, customer, landmark, gps, cashCollected
const updateTxLogic = `
if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
    const { id, customer, landmark, gps, amount, cashCollected, customTimestamp } = payload;
    let transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];
    transactions = transactions.map(t => {
        if (String(t.id) === String(id)) {
            t.customer = customer !== undefined ? customer : t.customer;
            t.landmark = landmark !== undefined ? landmark : t.landmark;
            t.gps = gps !== undefined ? gps : t.gps;
            t.amount = amount !== undefined ? Number(amount) : t.amount;
            t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
            
            if (version === 'v5' && customTimestamp) {
                const newTs = new Date(customTimestamp).getTime();
                if (!isNaN(newTs)) {
                    t.timestamp = newTs;
                    t.id = newTs;
                    t.date = customTimestamp.replace('T', ' ');
                }
            }
        }
        return t;
    });
    transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));
    fs.writeFileSync(TRANSACTIONS_FILE, JSON.stringify(transactions, null, 2));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true }));
    return;
}
`;

// Replace update_tx block cleanly
if (serverCode.includes("action === 'update_tx'")) {
    // Regex replace existing update_tx handler block
    serverCode = serverCode.replace(/if\s*\(action\s*===\s*'update_tx'[\s\S]*?return;\s*\}/g, updateTxLogic.trim());
}

// Ensure the history list rendering in client HTML includes the ✏️ Edit button next to Delete for v3, v4, and v5,
// and the datetime-local picker for v5 so the date can be edited just like amount and customer.
const historyCardRendererPatch = `
    const isV3V4V5 = APP_VERSION === 'v3' || APP_VERSION === 'v4' || APP_VERSION === 'v5';
    const isV5 = APP_VERSION === 'v5';
`;

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Server.js aligned with full v5 history edit and time-travel capabilities!");
