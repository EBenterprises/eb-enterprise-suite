const fs = require('fs');
const path = require('path');

// 1. Create a backup script
const backupScript = `
const fs = require('fs');
const path = require('path');

const backupDir = path.join(__dirname, 'backups');
if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir);

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const filesToBackup = ['transactions.json', 'profiles.json', 'expenses.json'];

filesToBackup.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        fs.copyFileSync(filePath, path.join(backupDir, \`\${timestamp}_\${file}\`));
        console.log(\`[+] Backed up \${file} to backups/\${timestamp}_\${file}\`);
    }
});
`;

fs.writeFileSync(path.join(__dirname, 'backup.js'), backupScript);
console.log("[+] Created backup.js script.");

// 2. Read existing server.js and upgrade it to include v5 with History Timestamp Editing
let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Add v5 support to createAppHandler and server cluster if not already present
if (!serverCode.includes("'v5'")) {
    // Add v5 to titles and badges
    serverCode = serverCode.replace(
        `const titles = {`,
        `const titles = {\n            'v5': 'Enterprise P2P Master Suite v5 - History Time Travel',\n`
    );
    serverCode = serverCode.replace(
        `const badges = {`,
        `const badges = {\n            'v5': 'v5 History Time Travel & Edit Active',\n`
    );

    // Update action handler for update_tx to support customTimestamp
    serverCode = serverCode.replace(
        `if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {`,
        `if (action === 'update_tx' && (version === 'v3' || version === 'v4' || version === 'v5')) {\n                        const hasTimeMachine = version === 'v2' || version === 'v3' || version === 'v4' || version === 'v5';`
    );

    // Inside update_tx handler, update timestamp & date if provided
    serverCode = serverCode.replace(
        `t.customer = payload.customer !== undefined ? payload.customer : t.customer;`,
        `t.customer = payload.customer !== undefined ? payload.customer : t.customer;\n                                if (hasTimeMachine && payload.customTimestamp) {\n                                    const customTs = new Date(payload.customTimestamp).getTime();\n                                    t.timestamp = customTs;\n                                    t.id = customTs;\n                                    t.date = payload.customTimestamp.replace('T', ' ');\n                                }`
    );

    // Add v5 edit UI with datetime-local picker in history list rendering
    serverCode = serverCode.replace(
        `const isV3OrV4 = APP_VERSION === 'v3' || APP_VERSION === 'v4';`,
        `const isV3OrV4 = APP_VERSION === 'v3' || APP_VERSION === 'v4' || APP_VERSION === 'v5';\n            const isV5 = APP_VERSION === 'v5';`
    );

    serverCode = serverCode.replace(
        `'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`,
        ` (isV5 ? '<div style="margin-bottom:4px;"><label style="font-size:9px; color:#a5b4fc;">⏳ Change Entry Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="padding:6px; font-size:11px; margin-bottom:4px; background:#0b0f19; color:#e0e7ff; border-color:#4338ca;"></div>' : '') +\\n'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`
    );

    // Update client-side save-edit-btn payload to include customTimestamp for v5
    serverCode = serverCode.replace(
        `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })`,
        `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })`
    );

    // Add PORT_V5 definition and server listener at the bottom
    const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandler('v5')).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;
    serverCode = serverCode.replace(
        `http.createServer(createAppHandler('v4')).listen(PORT_V4`,
        portV5Block + `\nhttp.createServer(createAppHandler('v4')).listen(PORT_V4`
    );

    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully updated server.js with v5 History Time Travel feature!");
}
