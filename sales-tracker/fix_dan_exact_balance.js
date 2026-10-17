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
                        // Amount 80, cash collected 0, balance 80 (or as specified)
                        t.amount = 80;
                        if (t.cashCollected !== undefined) t.cashCollected = 0;
                        if (t.balance !== undefined) t.balance = 80;
                        updated = true;
                        console.log(`[+] Updated Dan in ${file}: Amount=80, Cash=0, Balance=80`);
                    }
                });
                if (updated) {
                    fs.writeFileSync(filePath, JSON.stringify(raw, null, 2));
                }
            }
        } catch (e) {}
    }
});
