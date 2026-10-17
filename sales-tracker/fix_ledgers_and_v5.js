const fs = require('fs');
const path = require('path');

// 1. Fix transactions.json directly (Christy: cashCollected 0, balance = amount - 0; Dan's first tx: cashCollected 50, balance = 80 - 50 = 30)
const txPath = path.join(__dirname, 'transactions.json');
if (fs.existsSync(txPath)) {
    try {
        let raw = fs.readFileSync(txPath, 'utf8');
        let data = JSON.parse(raw);
        let list = Array.isArray(data) ? data : (data.transactions || data.txs || []);

        list.forEach(tx => {
            if (tx.customer) {
                const name = tx.customer.toLowerCase();
                if (name.includes('christy')) {
                    tx.cashCollected = 0;
                    tx.balance = Number(tx.amount || 0) - Number(tx.cashCollected || 0);
                }
                if (name === 'dan' && Number(tx.amount) === 80 && Number(tx.cashCollected) === 0) {
                    // Target Dan's first transaction / unpaid matching entry
                    tx.cashCollected = 50;
                    tx.balance = Number(tx.amount || 0) - Number(tx.cashCollected || 0);
                }
            }
        });

        fs.writeFileSync(txPath, JSON.stringify(data, null, 2));
        console.log("[+] Updated transactions.json balances correctly.");
    } catch (e) {
        console.error("Error fixing transactions.json:", e.message);
    }
}

// 2. Point server.js to use server_v5.js or run server_v5.js directly on port 51205
if (fs.existsSync('server_v5.js')) {
    fs.copyFileSync('server_v5.js', 'server.js');
    console.log("[+] Switched active server.js to server_v5.js (Port 51205).");
}
