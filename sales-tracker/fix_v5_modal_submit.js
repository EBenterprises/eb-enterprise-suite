const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// The issue is in the frontend HTML template generated inside server.js for v4/v5.
// The edit button / submit button inside the transaction history item calls updateTx or similar,
// but the input fields or event handler bindings might be missing or broken.
// Let's inspect or patch the HTML template's edit transaction handler where edit inputs are rendered.

// Let's check how the edit modal or inline edit form is rendered in the HTML inside server.js.
// In v4/v5, transactions in history have an edit button that opens an edit modal or inline form.
// Let's add a robust event listener or fix the submit handler script inside the HTML string in server.js.

console.log("[*] Inspecting server.js for edit modal submit logic...");

// Let's see what function handles saving edits in the frontend script. Usually it's updateTx or similar.
// Let's inject a definitive fix into the frontend script part of server.js where editing happens.

// We will replace or patch the frontend submit function for edits to ensure it grabs the correct values 
// and sends the POST request properly.

const targetSearch = `function updateTx(id)`;
const replacement = `
function updateTx(id) {
    const customer = document.getElementById('edit_cust_' + id) ? document.getElementById('edit_cust_' + id).value : '';
    const landmark = document.getElementById('edit_land_' + id) ? document.getElementById('edit_land_' + id).value : '';
    const amount = parseFloat(document.getElementById('edit_amt_' + id) ? document.getElementById('edit_amt_' + id).value : 0) || 0;
    const cashCollected = parseFloat(document.getElementById('edit_cash_' + id) ? document.getElementById('edit_cash_' + id).value : 0) || 0;
    const customTsEl = document.getElementById('edit_ts_' + id);
    const customTimestamp = customTsEl ? customTsEl.value : null;

    fetch('/api', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            action: 'update_tx',
            payload: { id, customer, landmark, amount, cashCollected, customTimestamp }
        })
    }).then(res => res.json()).then(data => {
        if (data.success) {
            alert('Transaction updated successfully!');
            loadData();
        } else {
            alert('Error: ' + (data.error || 'Failed to update'));
        }
    }).catch(err => {
        console.error(err);
        alert('Network error while updating transaction.');
    });
}

function oldUpdateTx(id)
`;

if (serverCode.includes('function updateTx(')) {
    // Let's make sure our working updateTx replaces any broken one
    serverCode = serverCode.replace(/function updateTx\([\s\S]*?\n}/, replacement);
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully updated frontend updateTx function in server.js!");
} else {
    console.log("[!] updateTx function not found directly, checking alternative patterns...");
}

