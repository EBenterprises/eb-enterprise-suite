const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = 51202;
const DATA_FILE = path.join(__dirname, '..', 'v5', 'transactions.json');

const html = `<!DOCTYPE html>
<html><head><title>Sales Tracker v2</title>
<style>body{background:#0d1117;color:#c9d1d9;font-family:monospace;padding:20px;}
.tx{background:#161b22;border:1px solid #30363d;padding:10px;margin-bottom:10px;border-radius:6px;}
.bal{color:#f85149;}.paid{color:#3fb950;}</style>
</head><body>
<h2>Sales Tracker v2 - Balance Tracker</h2>
<div id="out">Loading...</div>
<script>
fetch('/api/transactions').then(r=>r.json()).then(d=>{
    document.getElementById('out').innerHTML = d.map(t=>{
        const tot = t.total||t.amount||0;
        const pd = t.paid||t.cashCollected||0;
        const bal = tot - pd;
        return \`<div class="tx"><b>\${t.customer||'Anon'}</b> | Total: $\${tot} \vert{} Paid:$\${pd} | <span class="\${bal>0?'bal':'paid'}">Bal: $\${bal}</span></div>\`;
    }).join('');
});
</script></body></html>`;

http.createServer((req, res) => {
    if (req.url === '/') { res.writeHead(200, {'Content-Type': 'text/html'}); res.end(html); }
    else if (req.url === '/api/transactions') {
        fs.readFile(DATA_FILE, 'utf8', (e, d) => { res.writeHead(200, {'Content-Type':'application/json'}); res.end(d||'[]'); });
    }
}).listen(PORT, () => console.log(`[+] v2 active on :${PORT}`));
