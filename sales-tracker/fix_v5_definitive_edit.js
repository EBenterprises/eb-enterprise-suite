const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

console.log("[*] Analyzing and patching server.js for robust transaction editing...");

// 1. Ensure backend update_tx action handles all fields robustly
const backendOldHandler = `if (action === 'update_tx'`;
const backendFix = `
    if (action === 'update_tx') {
        const t = txs.find(x => x.id === Number(payload.id));
        if (t) {
            t.customer = payload.customer !== undefined ? payload.customer : t.customer;
            t.landmark = payload.landmark !== undefined ? payload.landmark : t.landmark;
            t.amount = payload.amount !== undefined ? Number(payload.amount) : t.amount;
            t.cashCollected = payload.cashCollected !== undefined ? Number(payload.cashCollected) : t.cashCollected;
            if (payload.customTimestamp) {
                const customTs = new Date(payload.customTimestamp).getTime();
                if (!isNaN(customTs)) {
                    if (customTs > Date.now()) {
                        return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));
                    }
                    t.timestamp = customTs;
                    t.id = customTs; // update id if time machine is used
                    t.date = payload.customTimestamp.replace('T', ' ');
                }
            }
            fs.writeFileSync(DATA_FILE, JSON.stringify(txs, null, 2));
            return res.writeHead(200, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: true, tx: t }));
        }
        return res.writeHead(404, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Transaction not found' }));
    }
    if (false && action === 'update_tx'`;

if (serverCode.includes("action === 'update_tx'")) {
    // Replace existing update_tx backend logic with our robust one
    // Let's do a safe string replacement or regex replacement
    serverCode = serverCode.replace(/if\s*\(\s*action\s*===\s*'update_tx'[\s\S]*?\n\s*\}/, backendFix);
}

// 2. Ensure frontend updateTx JS function is fully functional and present in the HTML template
const frontendUpdateTxFunc = `
function updateTx(id) {
    const custEl = document.getElementById('edit_cust_' + id);
    const landEl = document.getElementById('edit_land_' + id);
    const amtEl = document.getElementById('edit_amt_' + id);
    const cashEl = document.getElementById('edit_cash_' + id);
    const tsEl = document.getElementById('edit_ts_' + id);

    const customer = custEl ? custEl.value : '';
    const landmark = landEl ? landEl.value : '';
    const amount = amtEl ? parseFloat(amtEl.value) || 0 : 0;
    const cashCollected = cashEl ? parseFloat(cashEl.value) || 0 : 0;
    const customTimestamp = tsEl ? tsEl.value : null;

    fetch('/api', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action: 'update_tx',
            payload: { id, customer, landmark, amount, cashCollected, customTimestamp }
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            alert('Transaction updated successfully!');
            loadData();
        } else {
            alert('Error updating: ' + (data.error || 'Unknown error'));
        }
    })
    .catch(err => {
        console.error(err);
        alert('Network error while saving changes.');
    });
}
`;

// If updateTx function already exists in frontend, replace it; otherwise, append it before script tag ends or inside script
if (serverCode.includes('function updateTx(')) {
    serverCode = serverCode.replace(/function updateTx\([\s\S]*?\n\}/, frontendUpdateTxFunc);
} else {
    // Insert before </script>
    serverCode = serverCode.replace('</script>', frontendUpdateTxFunc + '\n</script>');
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Definitive edit and save functionality applied to server.js!");
