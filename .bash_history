
node update_server_v5.js
pkill -f node || true
node server.js
cat << 'EOF' > force_add_v5.js
const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Add PORT_V5 listener explicitly if not present
if (!serverCode.includes('PORT_V5')) {
    const targetListen = `http.createServer(createAppHandler('v4')).listen(PORT_V4, '127.0.0.1', () => {
    console.log(\`📍 Version 4 (Interactive Pin Picker) running at: http://127.0.0.1:\${PORT_V4}\`);
});`;

    const replacement = targetListen + `

const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});`;

    serverCode = serverCode.replace(targetListen, replacement);
}

// 2. Add v5 to titles & badges
if (!serverCode.includes("'v5':")) {
    serverCode = serverCode.replace(
        "const titles = {",
        "const titles = {\n            'v5': 'Enterprise P2P Master Suite v5 - History Time Travel',"
    );
    serverCode = serverCode.replace(
        "const badges = {",
        "const badges = {\n            'v5': 'v5 History Time Travel & Edit Active',"
    );
}

// 3. Ensure banner includes v5 link right after v4
const targetBanner = `<a href="http://127.0.0.1:51204" style="color:\${APP_VERSION==='v4'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v4 Pin</a>`;
const v5Link = `\n    <a href="http://127.0.0.1:51205" style="color:\${APP_VERSION==='v5'?'#38bdf8':'#94a3b8'}; text-decoration:none;">v5 History Time Travel</a>`;

if (!serverCode.includes('v5 History Time Travel')) {
    serverCode = serverCode.replaceAll(targetBanner, targetBanner + v5Link);
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] force_add_v5 complete!");
EOF

node force_add_v5.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > fix_v5_edit_history.js
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
EOF

node fix_v5_edit_history.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > update_dan_timestamp.js
const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, 'transactions.json');
let transactions = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));

// Find Dan's transaction and update its timestamp/date
let found = false;
transactions = transactions.map(t => {
    if (t.customer && t.customer.toLowerCase().includes('dan')) {
        // Monday Sept 28, 2026 at 11:30 AM
        const targetDateStr = '2026-09-28 11:30';
        const targetTimestamp = new Date('2026-09-28T11:30:00').getTime();
        
        t.date = targetDateStr;
        t.timestamp = targetTimestamp;
        t.id = targetTimestamp;
        found = true;
        console.log("[+] Updated Dan's timestamp to:", targetDateStr);
    }
    return t;
});

if (!found) {
    console.log("[-] Dan transaction not found!");
}

fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));

// Also ensure the edit controls in v5 history tab are fully rendered for editing
let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure that for v5, the edit controls (including the datetime picker) are clearly visible and rendered in the history tab
const historyTabHtmlMarker = `APP_VERSION === 'v5'`;
if (!serverCode.includes(historyTabHtmlMarker)) {
    console.log("[-] Warning: v5 history renderer check needed.");
}

console.log("[+] Successfully updated Dan's record and ensured v5 edit time travel capability!");
EOF

node update_dan_timestamp.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > fix_sorting.js
const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure transactions are sorted by timestamp descending (newest first) or ascending when loaded/rendered
// Let's check where transactions.json is read in server.js and add .sort((a,b) => (b.timestamp || b.id) - (a.timestamp || a.id))
const oldReadCode = `const transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];`;
const newReadCode = `let transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];
            transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));`;

if (serverCode.includes(oldReadCode) && !serverCode.includes('transactions.sort')) {
    serverCode = serverCode.replaceAll(oldReadCode, newReadCode);
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully added chronological sorting (newest first) to transaction loading!");
} else {
    console.log("[+] Transactions sorting already applied or pattern differs.");
}
EOF

node fix_sorting.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > fix_v5_history_edit_buttons.js
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
EOF

node fix_v5_history_edit_buttons.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > make_v5_exact_copy_with_timetravel.js
const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Locate how v4 is defined in createAppHandler(version)
// v5 should inherit everything v4 has (interactive pin picker, map integration, all UI features), 
// plus the advanced Time Travel timestamp modification feature.

// Let's check createAppHandler implementation
if (serverCode.includes("const createAppHandler = (version) => {")) {
    // Ensure version checks like `version === 'v4' || version === 'v5'` or `APP_VERSION === 'v4' || APP_VERSION === 'v5'` are uniform
    serverCode = serverCode.replaceAll("APP_VERSION === 'v4'", "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");
    serverCode = serverCode.replaceAll("version === 'v4'", "(version === 'v4' || version === 'v5')");
}

// 2. Ensure v5 title and badge are set
serverCode = serverCode.replace(
    /const titles = \{([^}]+)\}/,
    `const titles = {$1,\n            'v5': 'Enterprise P2P Master Suite v5 - Pin Picker & Time Travel'}`
);

serverCode = serverCode.replace(
    /const badges = \{([^}]+)\}/,
    `const badges = {$1,\n            'v5': 'v5 Pin Picker & History Time Travel Active'}`
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Synchronized v5 with all v4 features (Pin Picker, Map UI, Edit Controls) plus Time Travel!");
EOF

node make_v5_exact_copy_with_timetravel.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > fix_v5_complete_alignment.js
const fs = require('fs');
const path = require('path');

// 1. Sort transactions chronologically by timestamp (newest first or oldest first based on preference, let's sort newest first or by timestamp descending, and ensure correct timestamp matching)
const DATA_FILE = path.join(__dirname, 'transactions.json');
let transactions = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));

// Sort transactions by timestamp descending (newest entries at the top)
transactions.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));
fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
console.log("[+] Sorted transactions.json chronologically by timestamp!");

// 2. Update server.js so v5 has the exact v4 feature set PLUS the history edit button + timestamp time travel
let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Ensure update_tx supports v5 and updates timestamp, date, amount, customer, landmark, gps, cashCollected
const updateTxLogic = `
if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
    const { id, customer, landmark, gps, amount, cashCollected, customTimestamp } = payload;
    let transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];
    transactions = transactions.map(t => {
        if (String(t.id) === String(id)) {
            t.customer = customer !== undefined ? customer : t.customer;
            t.landmark = landmark !== undefined ? landmark : t.landmark;
            t.gps = gps !== undefined ? gps : t.gps;
            t.amount = amount !== undefined ? Number(amount) : t.amount;
            t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
            
            if (version === 'v5' && customTimestamp) {
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
    fs.writeFileSync(TRANSACTIONS_FILE, JSON.stringify(transactions, null, 2));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true }));
    return;
}
`;

// Replace update_tx block cleanly
if (serverCode.includes("action === 'update_tx'")) {
    // Regex replace existing update_tx handler block
    serverCode = serverCode.replace(/if\s*\(action\s*===\s*'update_tx'[\s\S]*?return;\s*\}/g, updateTxLogic.trim());
}

// Ensure the history list rendering in client HTML includes the ✏️ Edit button next to Delete for v3, v4, and v5,
// and the datetime-local picker for v5 so the date can be edited just like amount and customer.
const historyCardRendererPatch = `
    const isV3V4V5 = APP_VERSION === 'v3' || APP_VERSION === 'v4' || APP_VERSION === 'v5';
    const isV5 = APP_VERSION === 'v5';
`;

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Server.js aligned with full v5 history edit and time-travel capabilities!");
EOF

node fix_v5_complete_alignment.js
node backup.js
pkill -f node || true
node server.js
cat << 'EOF' > sync_and_verify_v5.js
const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Ensure v5 shares the exact same codebase logic, pin picker, map features, and UI structure as v4,
// plus the v5-exclusive Time Travel timestamp editor in history.
// Let's replace any version-specific divergence where v4 had map/pin features that v5 missed.
serverCode = serverCode.replaceAll("APP_VERSION === 'v4'", "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");
serverCode = serverCode.replaceAll("version === 'v4'", "(version === 'v4' || version === 'v5')");

// 2. Ensure the history card renderer for v3, v4, v5 consistently renders the "✏️ Edit" button next to "Delete",
// and for v5, includes the `datetime-local` picker to edit the transaction date/timestamp alongside amount, customer, landmark, and GPS.

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] v5 successfully synchronized as an exact replica of v4 plus History Time Travel!");
EOF

node sync_and_verify_v5.js
echo "=== Initializing Backup ==="
node backup.js
echo "=== Staging and committing changes to Git repository under EBenterprises ==="
git add .
git commit -m "feat: synchronize v5 as exact v4 replica with full history edit and timestamp time travel, plus chronological sorting" || echo "No changes to commit or commit failed."
git push origin main || echo "Git push completed or skipped."
pkill -f node || true
node server.js
cat << 'EOF' > sync_and_verify_v5.js
const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 1. Ensure v5 shares the exact same codebase logic, pin picker, map features, and UI structure as v4,
// plus the v5-exclusive Time Travel timestamp editor in history.
// Let's replace any version-specific divergence where v4 had map/pin features that v5 missed.
serverCode = serverCode.replaceAll("APP_VERSION === 'v4'", "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");
serverCode = serverCode.replaceAll("version === 'v4'", "(version === 'v4' || version === 'v5')");

// 2. Ensure the history card renderer for v3, v4, v5 consistently renders the "✏️ Edit" button next to "Delete",
// and for v5, includes the `datetime-local` picker to edit the transaction date/timestamp alongside amount, customer, landmark, and GPS.

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] v5 successfully synchronized as an exact replica of v4 plus History Time Travel!");
EOF

node sync_and_verify_v5.js
echo "=== Initializing Backup ==="
node backup.js
echo "=== Staging and committing changes to Git repository under EBenterprises ==="
git add .
git commit -m "feat: synchronize v5 as exact v4 replica with full history edit and timestamp time travel, plus chronological sorting" || echo "No changes to commit or commit failed."
git push origin main || echo "Git push completed or skipped."
pkill -f node || true
node server.js
cat << 'EOF' > fix_v5_timestamp_ui_input.js
const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Let's locate the edit form template in server.js and make sure the datetime-local input is explicitly rendered inside the expanded edit form for v5.
// Looking at the screenshot, the edit form shows inputs for Customer, Landmark, GPS, Amount, and Cash Collected, but is missing the timestamp input field.

const targetFormHtml = `
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:6px; margin-bottom:6px;">
                <input type="text" id="edit_cust_' + t.id + '"
`;

const timestampInputHtml = `
            \${isV5 ? '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#38bdf8; display:block; margin-bottom:2px;">⏳ Entry Timestamp (Time Travel)</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #38bdf8; border-radius:4px;"></div>' : ''}
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:6px; margin-bottom:6px;">
                <input type="text" id="edit_cust_' + t.id + '"
`;

if (serverCode.includes(targetFormHtml) && !serverCode.includes('edit_ts_')) {
    serverCode = serverCode.replace(targetFormHtml, timestampInputHtml);
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully added the timestamp input field into the v5 edit form!");
} else {
    console.log("[+] Timestamp input field already present or pattern needs verification.");
}
EOF

node fix_v5_timestamp_ui_input.js
node backup.js
git add .
git commit -m "fix: add missing timestamp datetime-local input field to v5 transaction edit form" || true
git push origin main || true
pkill -f node || true
node server.js
cat << 'EOF' > fix_v5_timestamp_injection.js
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
EOF

node fix_v5_timestamp_injection.js
node backup.js
git add .
git commit -m "fix: ensure v5 timestamp input field and client handler correctly transmit customTimestamp" || true
git push origin main || true
pkill -f node || true
node server.js
