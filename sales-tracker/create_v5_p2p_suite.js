const fs = require('fs');
const path = require('path');

console.log("[+] Initializing EB Enterprises P2P Master Suite v5 architecture...");

const suiteDir = './v5_p2p_master_suite';
const dirs = [
    suiteDir,
    `${suiteDir}/server`,
    `${suiteDir}/public`,
    `${suiteDir}/p2p`,
    `${suiteDir}/config`
];

dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// 1. P2P WebRTC / Signaling Core module
const p2pEngineCode = `
// EB Enterprises P2P Master Suite v5 - WebRTC Direct-Connect & Data Channel Engine
class P2PMasterSuiteV5 {
    constructor(nodeId) {
        this.nodeId = nodeId || 'node_' + Math.random().toString(36.substring(2, 9));
        this.peers = new Map();
        this.connections = new Map();
        console.log(\`[P2P v5] Initialized node: \${this.nodeId}\`);
    }

    createDataChannel(peerId, pc) {
        const dataChannel = pc.createDataChannel("eb_p2p_v5_channel");
        this.setupDataChannel(peerId, dataChannel);
        return dataChannel;
    }

    setupDataChannel(peerId, channel) {
        channel.onopen = () => console.log(\`[P2P v5] Data channel open with peer: \${peerId}\`);
        channel.onclose = () => console.log(\`[P2P v5] Data channel closed with peer: \${peerId}\`);
        channel.onmessage = (event) => {
            console.log(\`[P2P v5] Message received from \${peerId}:\`, event.data);
            this.handleIncomingMessage(peerId, event.data);
        };
        this.connections.set(peerId, channel);
    }

    handleIncomingMessage(peerId, rawData) {
        try {
            const msg = JSON.parse(rawData);
            console.log(\`[P2P v5] Parsed message type: \${msg.type}\`);
        } catch(e) {
            console.log(\`[P2P v5] Raw message: \${rawData}\`);
        }
    }

    broadcast(data) {
        const payload = JSON.stringify(data);
        for (const [peerId, channel] of this.connections.entries()) {
            if (channel.readyState === 'open') {
                channel.send(payload);
            }
        }
    }
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = P2PMasterSuiteV5;
}
`;

fs.writeFileSync(`${suiteDir}/p2p/p2p_engine.js`, p2pEngineCode);

// 2. Full-stack Server Daemon (Port 51205 for v5 suite)
const serverCode = `
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 51205;

const server = http.createServer((req, res) => {
    console.log(\`[v5 Master Suite] \${req.method} \-\> \${req.url}\`);
    
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
    return \`<!DOCTYPE html>
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
</html>\`;
}

server.listen(PORT, '127.0.0.1', () => {
    console.log(\`[+] EB Enterprises P2P Master Suite v5 running on http://127.0.0.1:\${PORT}\`);
});
`;

fs.writeFileSync(`${suiteDir}/server/server.js`, serverCode);

// 3. Package & Runner script
const runnerCode = `const { spawn } = require('child_process');
const path = require('path');

console.log("[+] Launching EB Enterprises P2P Master Suite v5 Server Daemon...");
const serverProcess = spawn('node', [path.join(__dirname, 'server/server.js')], {
    stdio: 'inherit'
});

serverProcess.on('error', (err) => {
    console.error('[-] Failed to start v5 server:', err);
});
`;

fs.writeFileSync(`${suiteDir}/start_v5.js`, runnerCode);
fs.chmodSync(`${suiteDir}/start_v5.js`, '755');

console.log("[+] v5 P2P Master Suite successfully generated at ~/sales-tracker/v5_p2p_master_suite");
