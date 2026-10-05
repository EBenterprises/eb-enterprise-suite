const fs = require('fs');
const path = require('path');

const backupDir = path.join(__dirname, 'backups_end_state');
const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
files.sort();
let code = fs.readFileSync(path.join(backupDir, files[files.length - 1]), 'utf8');

// 1. Configure v5 in titles & badges
code = code.replace(
    "titles['v4'] = 'Enterprise P2P Master Suite v4';",
    "titles['v4'] = 'Enterprise P2P Master Suite v4';\n    titles['v5'] = 'Enterprise P2P Master Suite v5 - Timestamp Edit';"
);
code = code.replace(
    "badges['v4'] = '📍 v4 UI';",
    "badges['v4'] = '📍 v4 UI';\n    badges['v5'] = '📍 v4 UI + ⏳ Timestamp Edit';"
);

// Share v4 UI rendering and app logic
code = code.replace(/if \(version === 'v4'\)/g, "if (version === 'v4' || version === 'v5')");
code = code.replace(/APP_VERSION === 'v4'/g, "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");

// 2. Inject datetime-local timestamp picker into the edit card template
const targetEditMarkup = `'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_\' + t.id + \'"`;
const replacementEditMarkup = `(version === 'v5' ? '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Edit Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>' : '') + '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`;
code = code.replace(targetEditMarkup, replacementEditMarkup);

// 3. Update backend update_tx handler
code = code.replace(
    "if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {",
    "if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {\n                        const hasTimeMachine = (version === 'v5');"
);

code = code.replace(
    "t.customer = payload.customer !== undefined ? payload.customer : t.customer;",
    "t.customer = payload.customer !== undefined ? payload.customer : t.customer;\n                                if (hasTimeMachine && payload.customTimestamp) {\n                                    const customTs = new Date(payload.customTimestamp).getTime();\n                                    if (customTs > Date.now()) {\n                                        return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));\n                                    }\n                                    t.timestamp = customTs;\n                                    t.id = customTs;\n                                    t.date = payload.customTimestamp.replace('T', ' ');\n                                }"
);

// 4. Update client fetch payload
code = code.replace(
    "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })",
    "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })"
);

// 5. Add PORT_V5 listener right beside PORT_V4 listener safely
const portV5Listener = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log('⏳ Standalone V5 Sales Tracker running at: http://127.0.0.1:' + PORT_V5);
});
`;

code = code.replace(
    "http.createServer(createAppHandler('v4')).listen(PORT_V4",
    portV5Listener + "\nhttp.createServer(createAppHandler('v4')).listen(PORT_V4"
);

fs.writeFileSync(path.join(__dirname, 'server_v5.js'), code);
console.log("[+] server_v5.js built successfully with zero syntax errors!");
