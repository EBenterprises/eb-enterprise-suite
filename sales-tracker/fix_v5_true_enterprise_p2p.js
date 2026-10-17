const fs = require('fs');
const path = require('path');

// 1. Restore fresh from end-state backup
const backupDir = path.join(__dirname, 'backups_end_state');
const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
files.sort();
fs.copyFileSync(path.join(backupDir, files[files.length - 1]), path.join(__dirname, 'server.js'));

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 2. Locate where `update_tx` is handled in backend and make sure it fully updates amount, cashCollected, customer, landmark, etc. for v4 / Enterprise P2P Master Suite
const backendOldUpdate = `if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {`;
const backendNewUpdate = `
    if (action === 'update_tx') {
        const t = txs.find(x => x.id === Number(payload.id));
        if (t) {
            t.customer = payload.customer !== undefined ? payload.customer : t.customer;
            t.landmark = payload.landmark !== undefined ? payload.landmark : t.landmark;
            t.amount = payload.amount !== undefined ? Number(payload.amount) : t.amount;
            t.cashCollected = payload.cashCollected !== undefined ? Number(payload.cashCollected) : t.cashCollected;
            
            fs.writeFileSync(DATA_FILE, JSON.stringify(txs, null, 2));
            return res.writeHead(200, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: true, tx: t }));
        }
        return res.writeHead(404, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Transaction not found' }));
    }
    if (false && action === 'update_tx'
`;

if (serverCode.includes(backendOldUpdate)) {
    serverCode = serverCode.replace(backendOldUpdate, backendNewUpdate);
}

// 3. Inject a bulletproof frontend `updateTx` and DOM binding right into the Enterprise P2P Master Suite v4/v5 UI template
const enterpriseUpdateTxSnippet = `
function updateTx(id) {
    const custEl = document.getElementById('edit_cust_' + id);
    const landEl = document.getElementById('edit_land_' + id);
    const amtEl = document.getElementById('edit_amt_' + id);
    const cashEl = document.getElementById('edit_cash_' + id);

    const customer = custEl ? custEl.value : '';
    const landmark = landEl ? landEl.value : '';
    const amount = amtEl ? parseFloat(amtEl.value) || 0 : 0;
    const cashCollected = cashEl ? parseFloat(cashEl.value) || 0 : 0;

    fetch('/api', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action: 'update_tx',
            payload: { id, customer, landmark, amount, cashCollected }
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            if (typeof loadData === 'function') {
                loadData();
            } else {
                location.reload();
            }
        } else {
            alert('Error updating transaction: ' + (data.error || 'Unknown error'));
        }
    })
    .catch(err => {
        console.error(err);
        alert('Network error while saving changes.');
    });
}
`;

if (serverCode.includes('function updateTx')) {
    serverCode = serverCode.replace(/function updateTx\([\s\S]*?\n\}/, enterpriseUpdateTxSnippet);
} else {
    serverCode = serverCode.replace('</script>', enterpriseUpdateTxSnippet + '\n</script>');
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Enterprise P2P Master Suite edit/save patch applied successfully!");
