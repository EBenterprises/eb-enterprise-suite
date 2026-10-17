
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51205;

const server = http.createServer((req, res) => {
    console.log(`[v5 Master Suite] ${req.method} -> ${req.url}`);
    
    if (req.url === '/' || req.url === '/index.html') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(getIndexHtml());
    } else if (req.url === '/api/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
            suite: "EB Enterprises P2P Master Suite", 
            version: "v5.0.0", 
            status: "active",
            timestamp: new Date().toISOString()
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

function getIndexHtml() {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EB Enterprises P2P Master Suite v5</title>
    <style>
        body { font-family: monospace; background: #0f172a; color: #38bdf8; margin: 0; padding: 20px; }
        .container { max-width: 800px; margin: auto; background: #1e293b; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
        h1 { color: #f8fafc; border-bottom: 2px solid #38bdf8; padding-bottom: 10px; }
        .card { background: #0f172a; padding: 15px; margin: 10px 0; border-radius: 6px; border-left: 4px solid #38bdf8; }
        button { background: #38bdf8; color: #0f172a; border: none; padding: 10px 15px; font-weight: bold; cursor: pointer; border-radius: 4px; margin-top: 10px; }
        button:hover { background: #0ea5e9; }
        pre { background: #090d16; padding: 10px; border-radius: 4px; overflow-x: auto; color: #a5f3fc; }
    </style>
</head>
<body>
    <div class="container">
        <h1>EB Enterprises P2P Master Suite v5</h1>
        <div class="card">
            <h3>System Status</h3>
            <p>Node Daemon: <span style="color: #4ade80;">ONLINE</span> (Port 51205)</p>
            <p>Architecture: P2P Direct-Connect & Distributed Ledger Engine</p>
        </div>
        <div class="card">
            <h3>Active Peers & Data Channels</h3>
            <button onclick="fetchStatus()">Check Node API</button>
            <pre id="output">Click button to query v5 node daemon...</pre>
        </div>
    </div>
    <script>
        async function fetchStatus() {
            try {
                const res = await fetch('/api/status');
                const data = await res.json();
                document.getElementById('output').innerText = JSON.stringify(data, null, 2);
            } catch(e) {
                document.getElementById('output').innerText = 'Error fetching status: ' + e.message;
            }
        }
    </script>
</body>
</html>`;
}

server.listen(PORT, '127.0.0.1', () => {
    console.log(`[+] EB Enterprises P2P Master Suite v5 running on http://127.0.0.1:${PORT}`);
});
