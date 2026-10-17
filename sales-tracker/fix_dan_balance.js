const fs = require('fs');
const path = require('path');

const salesDir = __dirname;
const files = fs.readdirSync(salesDir);

files.forEach(file => {
    if (file.endsWith('.json')) {
        const filePath = path.join(salesDir, file);
        try {
            let raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
            let txs = Array.isArray(raw) ? raw : (raw.transactions || raw.txs || null);
            
            if (Array.isArray(txs)) {
                let updated = false;
                txs.forEach(t => {
                    if (t && t.customer && String(t.customer).toLowerCase().includes('dan')) {
                        console.log(`[+] Found Dan in ${file} (ID: ${t.id}, Amount: ${t.amount}, CashCollected: ${t.cashCollected}, Balance: ${t.balance})`);
                        // Ensure balance or cash collected matches correct expectations (e.g. amount 80, cashCollected 75 -> balance 5 or 0 depending on view)
                        // Looking at screenshot: Amount $80, Bal: $5 (meaning 80 - 75 = 5 remaining balance)
                        t.amount = 80;
                        if (t.cashCollected !== undefined) {
                            t.cashCollected = 75;
                        }
                        if (t.balance !== undefined) {
                            t.balance = 5;
                        }
                        updated = true;
                    }
                });
                if (updated) {
                    fs.writeFileSync(filePath, JSON.stringify(raw, null, 2));
                    console.log(`[+] Saved updated balance/amount for Dan in ${file}`);
                }
            }
        } catch (e) {}
    }
});
