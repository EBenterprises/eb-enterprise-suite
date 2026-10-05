const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The issue: When rendering transaction cards or calculating customer balances across multiple transactions, 
// each transaction is currently computing `t.balance` as just its own `amount - cashCollected` rather than the running cumulative balance for that customer!
// Let's inspect how transactions are processed and sort them by timestamp/date, then compute running cumulative balances per customer.

const cumulativeBalanceLogic = `
function computeRunningBalances(transactions) {
    // Sort transactions chronologically by timestamp
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

// Let's check where DATA_FILE is read and transactions are mapped/returned in server.js
// Whenever transactions are loaded or saved, we should ensure running balances are computed per customer.

console.log("[+] Analyzing server.js for balance computation insertion.");
