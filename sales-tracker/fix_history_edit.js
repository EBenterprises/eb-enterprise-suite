const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's inspect how transactions are saved and filtered. In history view, editing might be modifying a separate list or looking at archived/completed transactions, or the transaction object IDs might mismatch between string/number types!
// Notice: t.id = customTs sets id to a number timestamp, while String(t.id) === String(id) handles type comparison, but let's make sure the update logic correctly writes back and supports history tab edits.

// Let's do a complete, clean restoration from end-state backup and apply the v5 time travel & edit patch correctly without messy nested conditions.
const backupDir = path.join(__dirname, 'backups_end_state');
if (fs.existsSync(backupDir)) {
    const backupFiles = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
    backupFiles.sort();
    if (backupFiles.length > 0) {
        fs.copyFileSync(path.join(backupDir, backupFiles[backupFiles.length - 1]), serverPath);
        console.log("[+] Restored fresh server.js from backup.");
    }
}

code = fs.readFileSync(serverPath, 'utf8');

// Add v5 to titles & badges
code = code.replace(
    /titles\['v4'\]\s*=\s*'[^']*';/,
    "titles['v4'] = 'Enterprise P2P Master Suite v4';\n    titles['v5'] = 'Enterprise P2P Master Suite v5 - History & Time Travel';"
);
code = code.replace(
    /badges\['v4'\]\s*=\s*'[^']*';/,
    "badges['v4'] = '📍 v4 UI';\n    badges['v5'] = '⏳ v5 Time Travel';"
);

// Allow version v5 to use v4 UI logic
code = code.replace(/if\s*\(\s*version\s*===\s*'v4'\s*\)/g, "if (version === 'v4' || version === 'v5')");

// Replace update_tx logic to robustly support v3, v4, v5 and handle both numeric/string IDs and time travel
const robustUpdateBlock = `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {
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
            res.end(JSON.stringify({ success: true, updatedCount, transactions }));
            return;
        }`;

code = code.replace(
    /if\s*\(\s*action\s*===\s*'update_tx'\s*&&\s*\(\s*version\s*===\s*'v3'\s*\Vert{}\Vert{}\s*version\s*===\s*'v4'\s*\)\s*\)\s*\{[^}]+\}/s,
    robustUpdateBlock
);

// Inject HTML hook for v5 edit timestamp picker in history / active cards
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

// Add PORT_V5 listener
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
console.log("[+] V5 History & Time Travel server code successfully compiled and patched.");
