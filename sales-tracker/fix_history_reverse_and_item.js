const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// 1. Fix sorting in client render loop so most recent is at the top:
// Instead of rendering globalData.transactions directly in order, we sort a copy in reverse chronological order:
// [...globalData.transactions].sort((a,b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0))

code = code.replace(
    /globalData\.transactions\.map\(t => \{/,
    "[...globalData.transactions].sort((a,b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0)).map(t => {"
);

// Also make sure server-side arrays are sorted descending when fetched or saved
code = code.replace(
    /txs\.sort\(\s*\(a,\s*b\)\s*=>\s*\([^)]+\)\s*\)/g,
    "txs.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0))"
);

// 2. Ensure Item Name is properly included in the sale form and rendered in the transaction card
const itemFieldHtml = `
<div style="margin-bottom:8px;">
    <label style="font-size:10px; color:#a5b4fc; display:block; margin-bottom:2px;">🏷️ Item / Product Name</label>
    <input type="text" id="itemInput" placeholder="e.g. Premium Item" style="width:100%; padding:6px; background:#0b0f19; color:#e0e7ff; border:1px solid #4338ca; border-radius:4px; font-size:12px;">
</div>
`;

// Insert itemFieldHtml before amountInput if not already present
if (!code.includes('id="itemInput"')) {
    code = code.replace(
        /<input type="number" id="amountInput"/,
        itemFieldHtml + '\n<input type="number" id="amountInput"'
    );
}

// Ensure client POST request sends itemName
code = code.replace(
    /customer:\s*document\.getElementById\('custInput'\)\.value\.trim\(\)/,
    "customer: document.getElementById('custInput').value.trim(), itemName: document.getElementById('itemInput') ? document.getElementById('itemInput').value.trim() : ''"
);

// Render item name badge on the transaction card if present
const cardItemDisplay = "'+ (t.itemName ? '<span style=\"color:#38bdf8; font-weight:600; margin-right:6px;\">[' + t.itemName + ']</span>' : '') + '";
code = code.replace(
    /('<strong>' \+ t\.customer \+ '<\/strong>')/,
    cardItemDisplay + " + $1"
);

fs.writeFileSync(serverPath, code);
console.log("[+] Successfully updated v5 UI: History now renders most recent on top, and Item Name is included in the sale form & record.");
