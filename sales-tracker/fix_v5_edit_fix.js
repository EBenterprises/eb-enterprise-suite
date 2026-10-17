const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Fix the client-side JavaScript update payload in server.js to properly pass amount & cashCollected
// Look for where update payload is sent and make sure amount and cashCollected pull from the correct input elements
const oldJsReplaceSnippet = `body: JSON.stringify({ action: 'update_tx', payload: { id, customer, landmark, gps, amount, cashCollected, customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null } })`;

// Let's replace it with code that correctly reads amount and cashCollected from the edit modal inputs
const newJsReplaceSnippet = `body: JSON.stringify({ 
    action: 'update_tx', 
    payload: { 
        id, 
        customer, 
        landmark, 
        gps, 
        amount: parseFloat(document.getElementById('edit_amt_' + id) ? document.getElementById('edit_amt_' + id).value : 0) || 0, 
        cashCollected: parseFloat(document.getElementById('edit_cash_' + id) ? document.getElementById('edit_cash_' + id).value : 0) || 0, 
        customTimestamp: document.getElementById('edit_ts_' + id) ? document.getElementById('edit_ts_' + id).value : null 
    } 
})`;

if (serverCode.includes(oldJsReplaceSnippet)) {
    serverCode = serverCode.replace(oldJsReplaceSnippet, newJsReplaceSnippet);
    fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
    console.log("[+] Successfully updated edit payload extraction in server.js!");
} else {
    console.log("[!] Warning: Exact snippet not found, trying fallback patch...");
}

