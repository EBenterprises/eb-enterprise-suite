const fs = require('fs');
const path = require('path');
const file = path.join(__dirname, 'server_v5.js');
let code = fs.readFileSync(file, 'utf8');

// Ensure the history rendering function properly populates globalData and loops over transactions
const oldHistorySnippet = `hist.innerHTML = 'No transactions recorded.';`;
const replacementHistorySnippet = `
if (!globalData.transactions || globalData.transactions.length === 0) {
    hist.innerHTML = 'No transactions recorded.';
} else {
    hist.innerHTML = globalData.transactions.map(t => \`
        <div class="ledger-item" style="padding:8px; border-bottom:1px solid #1e293b; display:flex; justify-content:space-between; align-items:center;">
            <div>
                <strong style="color:#38bdf8;">\${t.customer}</strong> <span style="font-size:11px; color:#94a3b8;">(\${t.date})</span><br>
                <small style="color:#cbd5e1;">\${t.item} - $\${t.amount} (Paid:$\${t.cashCollected})</small><br>
                <small style="color:#64748b;">📍 \${t.landmark || 'No landmark'}</small>
            </div>
            <div>
                <button onclick="openEditModal(\${t.id})" style="background:#4f46e5; color:white; border:none; padding:4px 8px; border-radius:4px; font-size:10px; cursor:pointer;">Edit</button>
            </div>
        </div>
    \`).join('');
}
`;

if (code.includes(oldHistorySnippet)) {
    code = code.replace(oldHistorySnippet, replacementHistorySnippet);
    fs.writeFileSync(file, code);
    console.log("[+] Patched history rendering successfully!");
} else {
    console.log("[-] Target history snippet not found, checking alternative...");
}
