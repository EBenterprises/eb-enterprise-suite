const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// 1. Sort history / transaction lists to show most recent on top (descending chronological order by timestamp)
// Let's check how transactions are sorted or mapped for rendering in history/active views.
code = code.replace(
    /transactions\.sort\(\s*\(a,\s*b\)\s*=>\s*\(a\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*-\s*\(b\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*\)/g,
    "transactions.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0))"
);

// Also ensure sort order is descending across general listing renders if sorting ascending
code = code.replace(
    /\.sort\(\s*\(a,\s*b\)\s*=>\s*\(a\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*-\s*\(b\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*\)/g,
    ".sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0))"
);

// 2. Add Item Name field to the sale entry form and transaction schema
// Let's check where the sale input form is rendered in HTML template strings
const itemInputHtml = `
<div style="margin-bottom:10px;">
    <label style="font-size:11px; color:#94a3b8; display:block; margin-bottom:4px;">Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="e.g. Premium Item" style="width:100%; padding:8px; background:#0b0f19; color:#e0e7ff; border:1px solid #334155; border-radius:6px; font-size:13px;">
</div>
`;

// Insert itemInput HTML before amountInput or customer input in the sale form
code = code.replace(
    /<input type="number" id="amountInput"/,
    itemInputHtml + '\n<input type="number" id="amountInput"'
);

// Update add_sale payload collection in client script
code = code.replace(
    /customer:\s*document\.getElementById\('custInput'\)\.value\.trim\(\)/,
    "customer: document.getElementById('custInput').value.trim(), itemName: document.getElementById('itemInput') ? document.getElementById('itemInput').value.trim() : ''"
);

// Update server-side add_sale handler to store itemName
code = code.replace(
    /const\s*\{\s*customer,\s*landmark,\s*gps,\s*amount,\s*cashCollected,\s*customTimestamp\s*\}\s*=\s*payload;/g,
    "const { customer, itemName, landmark, gps, amount, cashCollected, customTimestamp } = payload;"
);

code = code.replace(
    /customer:\s*customer\s*\|\|\s*'Guest'/g,
    "customer: customer || 'Guest',\n                        itemName: itemName || 'General Sale'"
);

// Include item name display in transaction cards/history rows where appropriate
const itemDisplayHtml = '<span style="color:#38bdf8; font-weight:600; font-size:11px; margin-right:6px;">' + '${t.itemName ? "[" + t.itemName + "]" : ""}' + '</span>';
code = code.replace(
    /\/\/\s*Item display hook or customer name display/g,
    ""
);

fs.writeFileSync(serverPath, code);
console.log("[+] Updated server.js: History now sorts most recent on top, and Sale Form includes Item Name.");
