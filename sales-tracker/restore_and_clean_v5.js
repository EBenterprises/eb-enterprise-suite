const fs = require('fs');
const path = require('path');

const backupDir = path.join(__dirname, 'backups_end_state');
if (!fs.existsSync(backupDir)) {
    console.error("[-] backups_end_state folder not found in sales-tracker!");
    process.exit(1);
}

const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
if (files.length === 0) {
    console.error("[-] No server.js backup found!");
    process.exit(1);
}

files.sort();
const latestServerBackup = path.join(backupDir, files[files.length - 1]);
fs.copyFileSync(latestServerBackup, path.join(__dirname, 'server.js'));
console.log(`[+] Restored server.js from ${files[files.length - 1]}`);

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Global chronological sorting helper
if (!serverCode.includes('getSortedTransactions')) {
    const helperCode = `
function getSortedTransactions() {
    let txs = readJson('transactions.json');
    if (Array.isArray(txs)) {
        txs.sort((a, b) => {
            const timeA = a.date ? new Date(a.date.replace(' ', 'T')).getTime() : (a.timestamp || a.id || 0);
            const timeB = b.date ? new Date(b.date.replace(' ', 'T')).getTime() : (b.timestamp || b.id || 0);
            return timeB - timeA;
        });
    }
    return txs;
}
`;
    serverCode = helperCode + '\n' + serverCode;
    serverCode = serverCode.replace(/readJson\(['"]transactions\.json['"]\)/g, 'getSortedTransactions()');
}

// Add V5 config identical to V4 UI + time travel editor
serverCode = serverCode.replace(`const titles = {`, `const titles = {\n            'v5': 'Enterprise P2P Master Suite v5 - History Time Travel',\n`);
serverCode = serverCode.replace(`const badges = {`, `const badges = {\n            'v5': '📍 v4 UI + ⏳ History Time Travel Active',\n`);

serverCode = serverCode.replace(/APP_VERSION === 'v4'/g, "(APP_VERSION === 'v4' || APP_VERSION === 'v5')");

const v4HistoryCardTarget = `'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`;
const v5HistoryCardReplacement = `(APP_VERSION === 'v5' ? '<div style="margin-bottom:4px;"><label style="font-size:9px; color:#a5b4fc;">⏳ Change Entry Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="padding:6px; font-size:11px; margin-bottom:4px; background:#0b0f19; color:#e0e7ff; border-color:#4338ca;"></div>' : '') + '\\n' + ` + v4HistoryCardTarget;

serverCode = serverCode.replace(v4HistoryCardTarget, v5HistoryCardReplacement);

serverCode = serverCode.replace(
    `if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {`,
    `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {\n                        const hasTimeMachine = version === 'v2' || version === 'v3' || version === 'v4' || version === 'v5';`
);

serverCode = serverCode.replace(
    `t.customer = payload.customer !== undefined ? payload.customer : t.customer;`,
    `t.customer = payload.customer !== undefined ? payload.customer : t.customer;\n                                if (hasTimeMachine && payload.customTimestamp) {\n                                    const customTs = new Date(payload.customTimestamp).getTime();\n                                    if (customTs > Date.now()) {\n                                        return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));\n                                    }\n                                    t.timestamp = customTs;\n                                    t.id = customTs;\n                                    t.date = payload.customTimestamp.replace('T', ' ');\n                                }`
);

serverCode = serverCode.replace(
    `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })`,
    `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })`
);

if (!serverCode.includes('PORT_V5')) {
    const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;
    serverCode = serverCode.replace(`http.createServer(createAppHandler('v4')).listen(PORT_V4`, portV5Block + `\nhttp.createServer(createAppHandler('v4')).listen(PORT_V4`);
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] V5 successfully built on top of V4 backup!");
