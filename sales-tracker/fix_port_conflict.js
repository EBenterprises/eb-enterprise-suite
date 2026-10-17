const fs = require('fs');

let code = fs.readFileSync('server.js', 'utf8');

// Inject update_tx_v5 action if not present
if (!code.includes('update_tx_v5')) {
    const v5Action = `
            if (action === 'update_tx_v5') {
                const { id, customer, amount, cashCollected, customTimestamp } = payload;
                let transactions = fs.existsSync(DATA_FILE) ? JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')) : [];
                transactions = transactions.map(t => {
                    if (String(t.id) === String(id)) {
                        t.customer = customer !== undefined ? customer : t.customer;
                        t.amount = amount !== undefined ? Number(amount) : t.amount;
                        t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
                        t.balance = Math.max(0, t.amount - t.cashCollected);
                        t.status = t.balance === 0 ? 'Paid' : 'Balance';
                        if (customTimestamp) {
                            const newTs = new Date(customTimestamp).getTime();
                            if (!isNaN(newTs)) {
                                t.timestamp = newTs;
                                t.id = newTs;
                                t.date = customTimestamp.replace('T', ' ');
                            }
                        }
                    }
                    return t;
                });
                transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));
                fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true }));
                return;
            }
`;
    if (code.includes("if (action ===")) {
        code = code.replace("if (action ===", v5Action + "\n            if (action ===");
    }
}

fs.writeFileSync('server_v5.js', code);
console.log('[+] server_v5.js generated without duplicate listener bindings.');
