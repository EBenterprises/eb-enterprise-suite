const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure update_tx handler correctly parses customTimestamp for v5
const oldUpdateHandler = `if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {`;
const newUpdateHandler = `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {`;

if (serverCode.includes(oldUpdateHandler)) {
    serverCode = serverCode.replace(oldUpdateHandler, newUpdateHandler);
}

// Ensure the timestamp assignment is present in update_tx
if (!serverCode.includes('payload.customTimestamp')) {
    serverCode = serverCode.replace(
        `t.customer = payload.customer !== undefined ? payload.customer : t.customer;`,
        `t.customer = payload.customer !== undefined ? payload.customer : t.customer;\n                                if (version === 'v5' && payload.customTimestamp) {\n                                    const customTs = new Date(payload.customTimestamp).getTime();\n                                    if (!isNaN(customTs)) {\n                                        t.timestamp = customTs;\n                                        t.id = customTs;\n                                        t.date = payload.customTimestamp.replace('T', ' ');\n                                    }\n                                }`
    );
}

// Ensure the HTML/JS client rendering includes the date-time input and passes customTimestamp in v5
const oldEditBtnRenderer = `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })`;
const newEditBtnRenderer = `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })`;

if (serverCode.includes(oldEditBtnRenderer)) {
    serverCode = serverCode.replace(oldEditBtnRenderer, newEditBtnRenderer);
}

// Ensure the datetime input field is rendered in v5 transaction history card
if (!serverCode.includes('edit_ts_')) {
    serverCode = serverCode.replace(
        `'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`,
        ` (APP_VERSION === 'v5' ? '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#38bdf8; display:block; margin-bottom:2px;">⏳ Entry Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #38bdf8; border-radius:4px;"></div>' : '') +\\n'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`
    );
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Successfully updated server.js with fully functional v5 History Time Travel timestamp editing!");
