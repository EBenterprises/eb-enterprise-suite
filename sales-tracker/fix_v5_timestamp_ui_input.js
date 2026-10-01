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
