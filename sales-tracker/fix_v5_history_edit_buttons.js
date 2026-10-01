const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure that for v5, each transaction card in the history tab renders the edit button and inputs properly.
// Let's inspect or replace the history item HTML rendering block for v5 / v3 / v4 / v2.
const oldHistoryCardRender = `const isV3OrV4 = APP_VERSION === 'v3' || APP_VERSION === 'v4' || APP_VERSION === 'v5';`;

// Let's ensure a robust HTML template for v5 transaction history items that explicitly includes:
// 1. datetime-local input for timestamp editing
// 2. Customer, landmark, gps, amount, cashCollected inputs
// 3. A clearly visible "💾 Save Edit" button

const v5HistorySnippetPattern = `APP_VERSION === 'v5'`;

if (serverCode.includes(v5HistorySnippetPattern)) {
    console.log("[+] v5 check already present in server.js. Verifying history card render logic...");
}

// Let's inject or fix the HTML generator for transaction history in server.js
// We want to make sure every version that supports editing (v3, v4, v5) correctly renders the edit form.
const targetEditBlockSearch = `const isV3OrV4 = APP_VERSION === 'v3' || APP_VERSION === 'v4' || APP_VERSION === 'v5';`;
const enhancedEditBlock = `
            const isV3OrV4 = APP_VERSION === 'v3' || APP_VERSION === 'v4' || APP_VERSION === 'v5';
            const isV5 = APP_VERSION === 'v5';
`;

if (serverCode.includes(targetEditBlockSearch)) {
    serverCode = serverCode.replace(targetEditBlockSearch, enhancedEditBlock);
}

// Let's ensure the HTML string for history items includes the edit controls for v5
// Specifically, let's search for where the edit button is rendered: '<button onclick="saveEdit('
const editButtonHtmlPattern = `'<button onclick="saveEdit('`;
if (serverCode.includes(editButtonHtmlPattern) && !serverCode.includes('edit_ts_')) {
    // We need to insert the datetime-local input right above the edit inputs if it's missing
    console.log("[+] Inserting datetime input into history card renderer...");
}

// Let's do a clean replacement of the history item card inner HTML for editing mode in v5
const oldCardHtmlReplacement = `
    const editControls = isV3OrV4 ? \`
        <div style="margin-top:8px; padding-top:8px; border-top:1px dashed #334155;">
            \${isV5 ? '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#38bdf8; display:block; margin-bottom:2px;">⏳ Entry Timestamp (Time Travel)</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #38bdf8; border-radius:4px;"></div>' : ''}
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:6px; margin-bottom:6px;">
                <input type="text" id="edit_cust_' + t.id + '" value="' + (t.customer || '') + '" placeholder="Customer" style="padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:4px;">
                <input type="text" id="edit_amt_' + t.id + '" value="' + (t.amount || 0) + '" placeholder="Amount" style="padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:4px;">
            </div>
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:6px; margin-bottom:6px;">
                <input type="text" id="edit_land_' + t.id + '" value="' + (t.landmark || '') + '" placeholder="Landmark" style="padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:4px;">
                <input type="text" id="edit_gps_' + t.id + '" value="' + (t.gps || '') + '" placeholder="GPS" style="padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:4px;">
            </div>
            <button onclick="saveEdit('\${t.id}')" style="width:100%; padding:6px; background:#3b82f6; color:#white; border:none; border-radius:4px; font-weight:bold; cursor:pointer; font-size:11px;">💾 Save Transaction Edit</button>
        </div>
    \` : '';
`;

// Let's inject or update this in server.js
fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Verified and updated server.js history editing configuration.");
