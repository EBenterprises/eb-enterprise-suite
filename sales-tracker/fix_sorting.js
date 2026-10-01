const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure transactions are sorted by timestamp descending (newest first) or ascending when loaded/rendered
// Let's check where transactions.json is read in server.js and add .sort((a,b) => (b.timestamp || b.id) - (a.timestamp || a.id))
const oldReadCode = `const transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];`;
const newReadCode = `let transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];
            transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));`;

if (serverCode.includes(oldReadCode) && !serverCode.includes('transactions.sort')) {
    serverCode = serverCode.replaceAll(oldReadCode, newReadCode);
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully added chronological sorting (newest first) to transaction loading!");
} else {
    console.log("[+] Transactions sorting already applied or pattern differs.");
}
