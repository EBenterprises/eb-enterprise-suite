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
                        console.log(`[+] Found Dan in ${file} (ID: ${t.id}, Amount: ${t.amount}) -> Changing to 80`);
                        t.amount = 80;
                        updated = true;
                    }
                });
                if (updated) {
                    fs.writeFileSync(filePath, JSON.stringify(raw, null, 2));
                    console.log(`[+] Saved updated ${file}`);
                }
            }
        } catch (e) {
            // ignore non-json or unparseable files
        }
    }
});
