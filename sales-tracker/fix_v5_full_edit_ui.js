const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Let's inspect how the HTML template in server.js renders the edit inputs and the update button for v4/v5.
// In v4/v5, when editing a transaction, the template typically renders inputs with IDs like edit_cust_..., edit_land_..., edit_amt_..., edit_cash_...
// And a save button calling updateTx(id).
// Let's inspect or patch the HTML template's inline edit / modal template inside createAppHandler.

// Let's replace the v4/v5 frontend update function inside the HTML string to ensure it correctly collects all values
// and re-renders/reloads data properly.

const oldHtmlSnippet = `function updateTx(id)`;
const robustUpdateTxJs = `
function updateTx(id) {
    const custEl = document.getElementById('edit_cust_' + id);
    const landEl = document.getElementById('edit_land_' + id);
    const amtEl = document.getElementById('edit_amt_' + id);
    const cashEl = document.getElementById('edit_cash_' + id);
    const tsEl = document.getElementById('edit_ts_' + id);

    const payload = {
        id: Number(id),
        customer: custEl ? custEl.value : '',
        landmark: landEl ? landEl.value : '',
        amount: amtEl ? parseFloat(amtEl.value) || 0 : 0,
        cashCollected: cashEl ? parseFloat(cashEl.value) || 0 : 0,
        customTimestamp: tsEl ? tsEl.value : null
    };

    fetch('/api', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'update_tx', payload })
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
            alert('Failed to update: ' + (data.error || 'Unknown error'));
        }
    })
    .catch(err => {
        console.error('Update error:', err);
        alert('Network error while updating transaction.');
    });
}
`;

// If function updateTx exists in the code, replace it. Otherwise, add it to the script section.
if (serverCode.includes('function updateTx')) {
    serverCode = serverCode.replace(/function updateTx\([\s\S]*?\n\}/, robustUpdateTxJs);
    console.log("[+] Replaced existing updateTx function in server.js");
} else {
    serverCode = serverCode.replace('</script>', robustUpdateTxJs + '\n</script>');
    console.log("[+] Appended robust updateTx function to script section in server.js");
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Successfully updated server.js with robust frontend edit handler!");
