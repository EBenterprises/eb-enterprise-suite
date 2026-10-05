const fs = require('fs');
const path = require('path');

// 1. Restore fresh from end-state backup
const backupDir = path.join(__dirname, 'backups_end_state');
const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
files.sort();
fs.copyFileSync(path.join(backupDir, files[files.length - 1]), path.join(__dirname, 'server.js'));

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 2. Add 'v5' config dictionary entries right alongside 'v4' inside createAppHandler
serverCode = serverCode.replace(
    "titles['v4'] = 'Enterprise P2P Master Suite v4';",
    "titles['v4'] = 'Enterprise P2P Master Suite v4';\n    titles['v5'] = 'Enterprise P2P Master Suite v5 - Full Time Travel';"
);
serverCode = serverCode.replace(
    "badges['v4'] = '📍 v4 UI';",
    "badges['v4'] = '📍 v4 UI';\n    badges['v5'] = '📍 v4 UI + ⏳ Time Travel';"
);

// Allow version === 'v5' to inherit version === 'v4' frontend UI code blocks safely
serverCode = serverCode.replace(
    /if \(version === 'v4'\)/g,
    "if (version === 'v4' || version === 'v5')"
);

// 3. Fix backend update_tx to handle amount, cashCollected, customer, landmark, and customTimestamp properly without syntax errors
const oldBackendUpdate = `if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {`;
const newBackendUpdate = `
    if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
        const hasTimeMachine = (version === 'v5');
        const t = txs.find(x => x.id === Number(payload.id));
        if (t) {
            t.customer = payload.customer !== undefined ? payload.customer : t.customer;
            t.landmark = payload.landmark !== undefined ? payload.landmark : t.landmark;
            t.amount = payload.amount !== undefined ? Number(payload.amount) : t.amount;
            t.cashCollected = payload.cashCollected !== undefined ? Number(payload.cashCollected) : t.cashCollected;
            if (hasTimeMachine && payload.customTimestamp) {
                const customTs = new Date(payload.customTimestamp).getTime();
                if (!isNaN(customTs)) {
                    if (customTs > Date.now()) {
                        return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));
                    }
                    t.timestamp = customTs;
                    t.id = customTs;
                    t.date = payload.customTimestamp.replace('T', ' ');
                }
            }
            fs.writeFileSync(DATA_FILE, JSON.stringify(txs, null, 2));
            return res.writeHead(200, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: true, tx: t }));
        }
        return res.writeHead(404, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Transaction not found' }));
    }
    if (false && action === 'update_tx'
`;

if (serverCode.includes(oldBackendUpdate)) {
    serverCode = serverCode.replace(oldBackendUpdate, newBackendUpdate);
}

// 4. Intercept HTML response in createAppHandler to inject datetime picker and correct functional buttons/inputs in v5 edit view
const htmlResponseHook = `if (version === 'v5') {
        html = html.replace(
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"',
            '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Edit Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" style="width:100%; padding:4px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>' +
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"'
        );
        html = html.replace(
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })",
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount: parseFloat(document.getElementById('edit_amt_' + id) ? document.getElementById('edit_amt_' + id).value : 0) || 0, cashCollected: parseFloat(document.getElementById('edit_cash_' + id) ? document.getElementById('edit_cash_' + id).value : 0) || 0, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })"
        );
    }`;

serverCode = serverCode.replace(
    "res.writeHead(200, { 'Content-Type': 'text/html' });",
    `res.writeHead(200, { 'Content-Type': 'text/html' });\n    ${htmlResponseHook}`
);

// 5. Add PORT_V5 listener
const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (Interactive V4 UI + History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;

serverCode = serverCode.replace(
    "http.createServer(createAppHandler('v4')).listen(PORT_V4);",
    "http.createServer(createAppHandler('v4')).listen(PORT_V4);\n" + portV5Block
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] V5 clean rewrite applied successfully!");
