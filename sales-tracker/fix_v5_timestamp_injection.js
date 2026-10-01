const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Let's ensure the edit card HTML builder string explicitly includes the timestamp input for v5.
// Let's check how editControls or history card HTML is generated in server.js.
// We will search for `saveEdit(` and insert the timestamp picker directly above the customer/amount inputs if missing.

const oldSaveEditCall = `onclick="saveEdit('${ t.id }')"`;
// Let's search for where the edit form container is defined or rendered:
// We want to make sure `isV5` renders the datetime-local input cleanly.

const timestampInputSnippet = `
    \${APP_VERSION === 'v5' ? '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#38bdf8; display:block; margin-bottom:2px;">⏳ Entry Timestamp (Time Travel)</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #38bdf8; border-radius:4px;"></div>' : ''}
`;

// Let's find where the inputs start inside the edit form and prepend the timestamp input if not already present
if (serverCode.includes('id="edit_cust_') && !serverCode.includes('edit_ts_')) {
    serverCode = serverCode.replace(
        `'<input type="text" id="edit_cust_'`,
        timestampInputSnippet + ` + '<input type="text" id="edit_cust_'`
    );
}

// Also ensure the client-side saveEdit function reads `edit_ts_` and sends `customTimestamp`
const oldSaveEditJs = `function saveEdit(id) {`;
const newSaveEditJsPatched = `
function saveEdit(id) {
    const customTimestamp = document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null;
    const customer = document.getElementById('edit_cust_' + id) ? document.getElementById('edit_cust_' + id).value : '';
    const landmark = document.getElementById('edit_land_' + id) ? document.getElementById('edit_land_' + id).value : '';
    const gps = document.getElementById('edit_gps_' + id) ? document.getElementById('edit_gps_' + id).value : '';
    const amount = document.getElementById('edit_amt_' + id) ? document.getElementById('edit_amt_' + id).value : 0;
    
    fetch('/api', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, customTimestamp } })
    }).then(res => res.json()).then(data => {
        if (data.success) location.reload();
        else alert('Error updating transaction');
    });
}
`;

// Replace existing saveEdit function if present
if (serverCode.includes('function saveEdit(')) {
    // Regex replace saveEdit function definition
    serverCode = serverCode.replace(/function saveEdit\([\s\S]*?\n\}\n/g, newSaveEditJsPatched.trim() + '\n');
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Successfully updated server.js with robust v5 timestamp input rendering and client-side payload handling!");
