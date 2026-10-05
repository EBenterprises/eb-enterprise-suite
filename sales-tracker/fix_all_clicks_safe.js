const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's find where .save-edit-btn is located using simple string indexing instead of fragile regex
const targetStr = "querySelectorAll('.save-edit-btn')";
const idx = code.indexOf(targetStr);
if (idx !== -1) {
    // Let's locate the enclosing function or replace the block safely by searching for the surrounding function boundaries
    console.log("[+] Found save-edit-btn in code.");
}

// Instead of regex replacement, let's restore cleanly from end-state backup and write a clean, robust event binding function that handles both save and edit buttons without syntax errors.
const backupDir = path.join(__dirname, 'backups_end_state');
if (fs.existsSync(backupDir)) {
    const backupFiles = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
    backupFiles.sort();
    if (backupFiles.length > 0) {
        fs.copyFileSync(path.join(backupDir, backupFiles[backupFiles.length - 1]), serverPath);
        console.log("[+] Restored fresh server.js from end-state backup.");
    }
}

code = fs.readFileSync(serverPath, 'utf8');

// Update v5 title & badges
code = code.replace(
    /titles\['v4'\]\s*=\s*'[^']*';/,
    "titles['v4'] = 'Enterprise P2P Master Suite v4';\n    titles['v5'] = 'Enterprise P2P Master Suite v5 - History & Time Travel';"
);
code = code.replace(
    /badges\['v4'\]\s*=\s*'[^']*';/,
    "badges['v4'] = '📍 v4 UI';\n    badges['v5'] = '⏳ v5 Time Travel';"
);

code = code.replace(/if\s*\(\s*version\s*===\s*'v4'\s*\)/g, "if (version === 'v4' || version === 'v5')");

// Add robust update_tx handler
const updateHandler = `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
            const hasTimeMachine = (version === 'v5');
            const { id, customer, landmark, gps, amount, cashCollected, customTimestamp } = payload;
            let transactions = fs.existsSync(TRANSACTIONS_FILE) ? JSON.parse(fs.readFileSync(TRANSACTIONS_FILE, 'utf8')) : [];
            let updatedCount = 0;
            transactions = transactions.map(t => {
                if (String(t.id) === String(id)) {
                    updatedCount++;
                    t.customer = customer !== undefined ? customer : t.customer;
                    t.landmark = landmark !== undefined ? landmark : t.landmark;
                    t.gps = gps !== undefined ? gps : t.gps;
                    t.amount = amount !== undefined ? Number(amount) : t.amount;
                    t.cashCollected = cashCollected !== undefined ? Number(cashCollected) : t.cashCollected;
                    if (hasTimeMachine && customTimestamp) {
                        const customTs = new Date(customTimestamp).getTime();
                        if (!isNaN(customTs)) {
                            t.timestamp = customTs;
                            t.id = customTs;
                            t.date = customTimestamp.replace('T', ' ');
                        }
                    }
                }
                return t;
            });
            fs.writeFileSync(TRANSACTIONS_FILE, JSON.stringify(transactions, null, 2));
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true, updatedCount }));
            return;
        }`;

code = code.replace(
    /if\s*\(\s*action\s*===\s*'update_tx'[^}]+\}\s*\)\s*\{[^}]+\}/s,
    updateHandler
);

// Inject v5 time picker and ensure proper fetch payload in client JS
const htmlHook = `
    if (version === 'v5') {
        html = html.replace(
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"',
            '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Time Travel Edit Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" style="width:100%; padding:4px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;" value="' + (new Date(t.timestamp || Date.now())).toISOString().slice(0,16) + '"></div>' +
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"'
        );
        html = html.replace(
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })",
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })"
        );
    }
`;

code = code.replace(
    /res\.writeHead\(200,\s*\{\s*'Content-Type':\s*'text\/html'\s*\}\);/,
    `res.writeHead(200, { 'Content-Type': 'text/html' });\n${htmlHook}`
);

// Add port 51205 listener
const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History & Time Travel Suite) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;

code = code.replace(
    /http\.createServer\(createAppHandler\('v4'\)\)\.listen\(PORT_V4,\s*[^)]+\);/,
    match => match + "\n" + portV5Block
);

fs.writeFileSync(serverPath, code);
console.log("[+] Clean v5 build successfully written.");
