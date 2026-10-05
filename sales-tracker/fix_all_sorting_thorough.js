const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Create a helper function for reading and sorting transactions
const helperCode = `
function getSortedTransactions() {
    let txs = readJson('transactions.json');
    if (Array.isArray(txs)) {
        txs.sort((a, b) => {
            const timeA = a.date ? new Date(a.date.replace(' ', 'T')).getTime() : (a.timestamp || a.id || 0);
            const timeB = b.date ? new Date(b.date.replace(' ', 'T')).getTime() : (b.timestamp || b.id || 0);
            return timeB - timeA;
        });
    }
    return txs;
}
`;

// Inject the helper if not already present
if (!serverCode.includes('function getSortedTransactions')) {
    serverCode = helperCode + '\n' + serverCode;
}

// 2. Replace direct readJson('transactions.json') calls with getSortedTransactions() where transactions are used
serverCode = serverCode.replace(/readJson\(['"]transactions\.json['"]\)/g, 'getSortedTransactions()');

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Successfully updated server.js with global getSortedTransactions() helper!");
