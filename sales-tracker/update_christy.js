const fs = require('fs');
const path = require('path');

const files = ['transactions.json', 'data.json'];
for (const file of files) {
    const p = path.join(__dirname, file);
    if (fs.existsSync(p)) {
        try {
            const raw = fs.readFileSync(p, 'utf8');
            let data = JSON.parse(raw);
            let updated = false;

            // Handle array or object with transactions
            let list = Array.isArray(data) ? data : (data.transactions || data.txs || []);
            
            list.forEach(tx => {
                if (tx.customer && tx.customer.toLowerCase().includes('christy')) {
                    tx.cashCollected = 0;
                    tx.balance = Number(tx.amount || 0) - Number(tx.cashCollected || 0);
                    updated = true;
                }
            });

            if (updated) {
                fs.writeFileSync(p, JSON.stringify(data, null, 2));
                console.log(`[+] Updated Christy records in ${file}`);
            }
        } catch (e) {
            console.error(`Error processing ${file}:`, e.message);
        }
    }
}
