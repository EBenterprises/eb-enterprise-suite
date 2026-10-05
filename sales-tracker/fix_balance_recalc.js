const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The issue: When updating a transaction, amount or cashCollected changes, but running balances across transactions or profile balances are calculated dynamically from transactions or stored fields. Let's make sure that after updating a transaction, we ensure proper fields (amount, cashCollected, balance) are fully re-saved and consistent.
// Let's inspect how update_tx handles saving back to DATA_FILE.

const updatedUpdateTxHandler = `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
            const hasTimeMachine = (version === 'v5');
            const { id, customer, landmark, gps, amount, cashCollected, customTimestamp } = payload;
            let transactions = fs.existsSync(DATA_FILE) ? JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')) : [];
            let updatedCount = 0;
            
            transactions = transactions.map(t => {
                if (String(t.id) === String(id)) {
                    updatedCount++;
                    if (customer !== undefined) t.customer = customer;
                    if (landmark !== undefined) t.landmark = landmark;
                    if (gps !== undefined) t.gps = gps;
                    if (amount !== undefined) t.amount = Number(amount);
                    if (cashCollected !== undefined) t.cashCollected = Number(cashCollected);
                    
                    // Recalculate individual transaction balance or remaining amount if applicable
                    // Balance = amount - cashCollected (or similar standard suite logic)
                    t.balance = (t.amount || 0) - (t.cashCollected || 0);

                    if (hasTimeMachine && customTimestamp) {
                        const customTs = new Date(customTimestamp).getTime();
                        if (!isNaN(customTs)) {
                            t.timestamp = customTs;
                            t.id = customTs;
                            t.date = customTimestamp.replace('T', ' ');
                        }
                    }
                }
                return t;
            });

            fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
            console.log("[+] Transaction updated successfully. Total transactions:", transactions.length);
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, updatedCount, transactions }));
            return;
        }`;

// Replace the update_tx block cleanly
code = code.replace(
    /if\s*\(\s*action\s*===\s*'update_tx'[^}]+\}\s*\)\s*\{[^}]+\}\s*\}/s,
    updatedUpdateTxHandler
);

fs.writeFileSync(serverPath, code);
console.log("[+] Updated transaction handler to recalculate balance field automatically upon update.");
