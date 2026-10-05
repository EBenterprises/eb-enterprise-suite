const fs = require('fs');
const path = require('path');

const dataFile = path.join(__dirname, 'transactions.json');
if (fs.existsSync(dataFile)) {
    let transactions = JSON.parse(fs.readFileSync(dataFile, 'utf8'));
    
    // Let's recalculate balance for every transaction consistently: balance = amount - cashCollected
    // Or if balances are customer-based, let's see how the app calculates balances.
    transactions = transactions.map(t => {
        t.amount = Number(t.amount) || 0;
        t.cashCollected = Number(t.cashCollected) || 0;
        t.balance = t.amount - t.cashCollected;
        return t;
    });

    fs.writeFileSync(dataFile, JSON.stringify(transactions, null, 2));
    console.log("[+] Recalculated balances for all transactions in transactions.json");
}
