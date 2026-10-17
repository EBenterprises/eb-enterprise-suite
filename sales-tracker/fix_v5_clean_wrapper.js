const fs = require('fs');
const path = require('path');

// 1. Restore fresh from end-state backup
const backupDir = path.join(__dirname, 'backups_end_state');
if (!fs.existsSync(backupDir)) {
    console.error("[-] Error: backups_end_state directory not found!");
    process.exit(1);
}
const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
files.sort();
if (files.length === 0) {
    console.error("[-] Error: No backup server.js files found!");
    process.exit(1);
}
const latestBackup = files[files.length - 1];
console.log("[+] Using backup file:", latestBackup);
fs.copyFileSync(path.join(backupDir, latestBackup), path.join(__dirname, 'server.js'));

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 2. Clean up any previous broken v5 blocks
serverCode = serverCode.replace(/const PORT_V5[\s\S]*?\}\);\n?/g, '');
serverCode = serverCode.replace(/function createAppHandlerV5[\s\S]*?\n}\n/g, '');

// 3. Add 'v5' config dictionary entries right alongside 'v4' inside createAppHandler
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

// Enable time travel update logic when version is v5
serverCode = serverCode.replace(
    "if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {",
    "if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {\n            const hasTimeMachine = (version === 'v5');"
);

serverCode = serverCode.replace(
    "t.customer = payload.customer !== undefined ? payload.customer : t.customer;",
    "t.customer = payload.customer !== undefined ? payload.customer : t.customer;\n            if (hasTimeMachine && payload.customTimestamp) {\n                const customTs = new Date(payload.customTimestamp).getTime();\n                if (customTs > Date.now()) {\n                    return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));\n                }\n                t.timestamp = customTs;\n                t.id = customTs;\n                t.date = payload.customTimestamp.replace('T', ' ');\n            }"
);

// Intercept HTML response in createAppHandler to inject the datetime-local picker into the edit card if version is v5
const htmlResponseHook = `
    if (version === 'v5') {
        html = html.replace(
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"',
            '<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Edit Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" style="width:100%; padding:4px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>' +
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"'
        );
        html = html.replace(
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })",
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })"
        );
    }
`;

// Insert the hook right before html is returned or sent
serverCode = serverCode.replace(
    "res.writeHead(200, { 'Content-Type': 'text/html' });",
    "res.writeHead(200, { 'Content-Type': 'text/html' });\n" + htmlResponseHook
);

// Add PORT_V5 listener right alongside PORT_V4
const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (Interactive V4 UI + History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;

serverCode = serverCode.replace(
    "http.createServer(createAppHandler('v4')).listen(PORT_V4);",
    portV5BrandReplace = "http.createServer(createAppHandler('v4')).listen(PORT_V4);\n" + portV5Block
);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] V5 clean wrapper applied successfully!");
