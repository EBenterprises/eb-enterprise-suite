const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = 51201;
const DATA_FILE = path.join(__dirname, '..', 'v5', 'transactions.json');

const html = `<!DOCTYPE html>
<html><head><title>Sales Tracker v1</title>
<style>body{background:#0d1117;color:#c9d1d9;font-family:monospace;padding:20px;}
.tx{background:#161b22;border:1px solid #30363d;padding:10px;margin-bottom:10px;border-radius:6px;}</style>
</head><body>
<h2>Sales Tracker v1 - Raw Ledger</h2>
<div id="out">Loading...</div>
<script>
fetch('/api/transactions').then(r=>r.json()).then(d=>{
    document.getElementById('out').innerHTML = d.map(t=>\`
        <div class="tx"><b>\${t.customer||'Anon'}</b> - \${t.item||'Item'}<br>Total: $\${t.total\vert{}\vert{}t.amount\vert{}\vert{}0} \vert{} Paid:$\${t.paid||t.cashCollected||0}</div>
    \`).join('');
});
</script></body></html>`;

http.createServer((req, res) => {
    if (req.url === '/') { res.writeHead(200, {'Content-Type': 'text/html'}); res.end(html); }
    else if (req.url === '/api/transactions') {
        fs.readFile(DATA_FILE, 'utf8', (e, d) => { res.writeHead(200, {'Content-Type':'application/json'}); res.end(d||'[]'); });
    }
}).listen(PORT, () => console.log(`[+] v1 active on :${PORT}`));
