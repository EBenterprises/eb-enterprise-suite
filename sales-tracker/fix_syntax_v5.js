const fs = require('fs');
const path = require('path');

// 1. Restore fresh from end-state backup
const backupDir = path.join(__dirname, 'backups_end_state');
const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
files.sort();
fs.copyFileSync(path.join(backupDir, files[files.length - 1]), path.join(__dirname, 'server.js'));

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// 2. Strip any previous PORT_V5 or createAppHandlerV5 blocks
serverCode = serverCode.replace(/const PORT_V5[\s\S]*?\}\);\n?/g, '');
serverCode = serverCode.replace(/function createAppHandlerV5[\s\S]*?\n\}\n\}/g, '');

// 3. Extract exact v4 function block safely
const startIndex = serverCode.indexOf('function createAppHandler(version) {');
if (startIndex === -1) {
    console.error("[-] createAppHandler not found!");
    process.exit(1);
}

// Find matching closing brace
let braceCount = 0;
let endIndex = -1;
let inside = false;
for (let i = startIndex; i < serverCode.length; i++) {
    if (serverCode[i] === '{') {
        braceCount++;
        inside = true;
    } else if (serverCode[i] === '}') {
        braceCount--;
    }
    if (inside && braceCount === 0) {
        endIndex = i + 1;
        break;
    }
}

if (endIndex === -1) {
    console.error("[-] Could not find end of createAppHandler!");
    process.exit(1);
}

let v4FuncCode = serverCode.substring(startIndex, endIndex);

// Build v5 function code by modifying the v4 code
let v5FuncCode = v4FuncCode.replace('function createAppHandler(version)', 'function createAppHandlerV5()');

// Customize branding for v5 inside the function
v5FuncCode = v5FuncCode.replace(`titles['v4'] || 'Enterprise P2P Master Suite v4'`, `'Enterprise P2P Master Suite v5 - Full Time Travel'`);
v5FuncCode = v5FuncCode.replace(`badges['v4'] || '📍 v4 UI'`, `'📍 v4 UI + ⏳ History Time Travel'`);

// Inject the datetime-local timestamp input into the history edit card
const targetCard = `'<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"`;
const injectedCard = `'<div style="margin-bottom:6px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Edit Entry Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" value="' + (t.date ? t.date.replace(' ', 'T') : '') + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>' + '\\n' + ` + targetCard;

v5FuncCode = v5FuncCode.replace(targetCard, injectedCard);

// Enable time travel update logic & future date check in update_tx
v5FuncCode = v5FuncCode.replace(
    `if (action === 'update_tx' && (version === 'v3' || version === 'v4')) {`,
    `if (action === 'update_tx') {\n                        const hasTimeMachine = true;`
);

v5FuncCode = v5FuncCode.replace(
    `t.customer = payload.customer !== undefined ? payload.customer : t.customer;`,
    `t.customer = payload.customer !== undefined ? payload.customer : t.customer;\n                                if (hasTimeMachine && payload.customTimestamp) {\n                                    const customTs = new Date(payload.customTimestamp).getTime();\n                                    if (customTs > Date.now()) {\n                                        return res.writeHead(400, { 'Content-Type': 'application/json' }).end(JSON.stringify({ success: false, error: 'Cannot travel into the future!' }));\n                                    }\n                                    t.timestamp = customTs;\n                                    t.id = customTs;\n                                    t.date = payload.customTimestamp.replace('T', ' ');\n                                }`
);

// Pass customTimestamp in client-side saveEdit fetch call
v5FuncCode = v5FuncCode.replace(
    `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })`,
    `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })`
);

// Append createAppHandlerV5 definition to serverCode
serverCode += `\n\n${v5FuncCode}\n`;

// Add single PORT_V5 listener right above PORT_V4 listener
const portV5Block = `
const PORT_V5 = 51205;
http.createServer(createAppHandlerV5()).listen(PORT_V5, '127.0.0.1', () => {
    console.log(\`⏳ Version 5 (Interactive V4 UI + History Time Travel) running at: http://127.0.0.1:\${PORT_V5}\`);
});
`;

serverCode = serverCode.replace(`http.createServer(createAppHandler('v4')).listen(PORT_V4`, portV5Block + `\nhttp.createServer(createAppHandler('v4')).listen(PORT_V4`);

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] V5 syntax successfully balanced and compiled!");
