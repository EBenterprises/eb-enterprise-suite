const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let serverCode = fs.readFileSync(serverPath, 'utf8');

// 1. Ensure the V5 HTML response hook safely injects the datetime-local input into the edit modal
const targetHook = `if (version === 'v5') {`;
if (!serverCode.includes(targetHook)) {
    console.log("[-] V5 hook not found. Applying standard injection...");
}

// Update the V5 injection block to cleanly insert the timestamp editor into the transaction modal
const v5Injection = `
    if (version === 'v5') {
        html = html.replace(
            '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"',
            '<div style="margin-bottom:8px;"><label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">⏳ Edit Record Timestamp</label><input type="datetime-local" id="edit_ts_' + t.id + '" style="width:100%; padding:6px; font-size:11px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px;"></div>' + '<div style="display:flex; gap:4px;"><input type="number" id="edit_amt_' + t.id + '"'
        );
        html = html.replace(
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected } })",
            "body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })"
        );
    }
`;

// Replace or append the hook beforewriteHead
if (serverCode.includes('res.writeHead(200, { \'Content-Type\': \'text/html\' });')) {
    serverCode = serverCode.replace(
        'res.writeHead(200, { \'Content-Type\': \'text/html\' });',
        'res.writeHead(200, { \'Content-Type\': \'text/html\' });\n' + v5Injection
    );
}

// 2. Ensure backend server processes customTimestamp when updating transactions
const backendTarget = `t.customer = payload.customer !== undefined ? payload.customer : t.customer;`;
const backendUpdate = `
                                t.customer = payload.customer !== undefined ? payload.customer : t.customer;
                                if (payload.customTimestamp) {
                                    const customTs = new Date(payload.customTimestamp).getTime();
                                    if (!isNaN(customTs)) {
                                        t.timestamp = customTs;
                                        t.date = payload.customTimestamp.replace('T', ' ');
                                    }
                                }
`;

serverCode = serverCode.replace(backendTarget, backendUpdate);

fs.writeFileSync(serverPath, serverCode);
console.log("[+] Timestamp edit patch applied successfully!");
