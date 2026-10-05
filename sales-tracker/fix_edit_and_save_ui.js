const fs = require('fs');
const path = require('path');

// 1. Let's patch server.js so the backend update_tx correctly handles amount, cashCollected, customer, and balance
const serverPath = path.join(__dirname, 'server.js');
if (fs.existsSync(serverPath)) {
    let serverCode = fs.readFileSync(serverPath, 'utf8');

    // Make sure the backend API route handles update_tx precisely
    const backendUpdateSnippet = `
    if (action === 'update_tx') {
        const txsFile = DATA_FILE || path.join(__dirname, 'data.json');
        let rawData = [];
        try {
            if (fs.existsSync(txsFile)) {
                let parsed = JSON.parse(fs.readFileSync(txsFile, 'utf8'));
                rawData = Array.isArray(parsed) ? parsed : (parsed.transactions || parsed.txs || []);
            }
        } catch (e) {}

        const targetId = Number(payload.id);
        const t = rawData.find(x => Number(x.id) === targetId);
        if (t) {
            t.customer = payload.customer !== undefined ? payload.customer : t.customer;
            t.landmark = payload.landmark !== undefined ? payload.landmark : t.landmark;
            t.amount = payload.amount !== undefined ? Number(payload.amount) : t.amount;
            t.cashCollected = payload.cashCollected !== undefined ? Number(payload.cashCollected) : t.cashCollected;
            if (t.balance !== undefined) {
                t.balance = Number(t.amount) - Number(t.cashCollected);
            }

            fs.writeFileSync(txsFile, JSON.stringify(rawData, null, 2));
            return res.writeHead(200, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: true, tx: t }));
        }
        return res.writeHead(404, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Transaction not found' }));
    }
    `;

    // Inject or replace update_tx backend handler
    if (serverCode.includes("action === 'update_tx'")) {
        serverCode = serverCode.replace(/if\s*\(\s*action\s*===\s*'update_tx'[\s\S]*?\n\s*\}/, backendUpdateSnippet);
    } else if (serverCode.includes("let action =") || serverCode.includes("const action =")) {
        serverCode = serverCode.replace(
            /(let|const)\s+action\s*=\s*[^;]+;/i,
            match => match + '\n' + backendUpdateSnippet
        );
    }

    // 2. Fix the frontend updateTx function in all HTML templates so clicking "Save" or "Update" correctly pulls input values and sends them to /api
    const frontendUpdateScript = `
<script>
function updateTx(id) {
    const custEl = document.getElementById('edit_cust_' + id);
    const landEl = document.getElementById('edit_land_' + id);
    const amtEl = document.getElementById('edit_amt_' + id);
    const cashEl = document.getElementById('edit_cash_' + id);

    const payload = {
        id: Number(id),
        customer: custEl ? custEl.value : '',
        landmark: landEl ? landEl.value : '',
        amount: amtEl ? parseFloat(amtEl.value) || 0 : 0,
        cashCollected: cashEl ? parseFloat(cashEl.value) || 0 : 0
    };

    fetch('/api', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'update_tx', payload })
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            alert('Transaction updated successfully!');
            if (typeof loadData === 'function') {
                loadData();
            } else {
                location.reload();
            }
        } else {
            alert('Error updating: ' + (data.error || 'Unknown error'));
        }
    })
    .catch(err => {
        console.error('Update error:', err);
        alert('Network error while updating transaction.');
    });
}
</script>
`;

    // Replace existing updateTx function or insert before closing body/script
    if (serverCode.includes('function updateTx')) {
        serverCode = serverCode.replace(/function updateTx\([\s\S]*?\n\}/g, frontendUpdateScript);
    } else {
        serverCode = serverCode.replace('</body>', frontendUpdateScript + '\n</body>');
    }

    fs.writeFileSync(serverPath, serverCode);
    console.log("[+] Successfully patched server.js with fully working edit inputs and balance calculation!");
}
