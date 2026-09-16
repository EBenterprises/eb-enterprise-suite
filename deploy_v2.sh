#!/bin/bash
echo "[*] Initializing DarkNet Communications Enclave V2..."
cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not detected. Aborting."
    exit 1
fi

mkdir -p darknet_chat_v2/server darknet_chat_v2/frontend darknet_chat_v2/assets

cat << 'INNER_EOF' > darknet_chat_v2/server/expansions.py
import time
import os
import base64

DEAD_DROP_VAULT = []
CIRCUIT_LOG = []

def handle_dead_drop(body_data):
    recipient = body_data.get('recipient', 'UNKNOWN')
    payload = body_data.get('payload', '')
    passphrase_hash = body_data.get('passphrase_hash', '')
    
    drop_id = base64.b32encode(os.urandom(4)).decode('utf-8').strip('=')
    drop = {
        "drop_id": drop_id,
        "recipient": recipient,
        "payload": base64.b64encode(payload.encode('utf-8')).decode('utf-8'),
        "passphrase_hash": passphrase_hash,
        "retrieved": False,
        "created_at": time.time()
    }
    DEAD_DROP_VAULT.append(drop)
    return {"status": "DEAD_DROP_ARMED", "drop_id": drop_id}

def get_dead_drops():
    return [d for d in DEAD_DROP_VAULT if not d["retrieved"]]

def rotate_circuit():
    nodes = [
        {"node_id": "TOR_EXIT_0x8B", "latency": "31ms", "status": "ROTATED"},
        {"node_id": "I2P_HOP_0x9C", "latency": "64ms", "status": "SECURE"},
        {"node_id": "DARK_RELAY_0x33", "latency": "19ms", "status": "ACTIVE"}
    ]
    CIRCUIT_LOG.append({"timestamp": time.time(), "nodes": nodes})
    return nodes
INNER_EOF

cat << 'INNER_EOF' > darknet_chat_v2/server/server.py
import http.server
import socketserver
import json
import os
import time
import base64
from urllib.parse import urlparse
from expansions import handle_dead_drop, get_dead_drops, rotate_circuit

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../assets")

MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_RELAY_0x9A", "latency": "42ms", "status": "SECURE"},
    {"node_id": "I2P_TUNNEL_0x4F", "latency": "88ms", "status": "ENCRYPTED"},
    {"node_id": "DARK_HOP_0x11", "latency": "15ms", "status": "ACTIVE"}
]

class DarkNetHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        global ACTIVE_NODES
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')

        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        if parsed_path.path == '/api/send':
            try:
                recipient = data.get('recipient', 'ANONYMOUS')
                payload = data.get('payload', '')
                burn_timer = int(data.get('burn_timer', 10))

                packet = {
                    "id": base64.b32encode(os.urandom(5)).decode('utf-8').strip('='),
                    "recipient": recipient,
                    "payload": base64.b64encode(payload.encode('utf-8')).decode('utf-8'),
                    "timestamp": time.time(),
                    "expires_at": time.time() + burn_timer,
                    "hops": ACTIVE_NODES
                }
                MESSAGE_VAULT.append(packet)

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "SUCCESS", "packet_id": packet["id"]}).encode('utf-8'))
            except Exception as e:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode('utf-8'))

        elif parsed_path.path == '/api/deaddrop/create':
            response = handle_dead_drop(data)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))

        elif parsed_path.path == '/api/circuit/rotate':
            ACTIVE_NODES = rotate_circuit()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "CIRCUIT_ROTATED", "nodes": ACTIVE_NODES}).encode('utf-8'))

        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        global MESSAGE_VAULT
        parsed_path = urlparse(self.path)
        if parsed_path.path == '/api/messages':
            current_time = time.time()
            MESSAGE_VAULT = [m for m in MESSAGE_VAULT if m["expires_at"] > current_time]

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(MESSAGE_VAULT).encode('utf-8'))

        elif parsed_path.path == '/api/nodes':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(ACTIVE_NODES).encode('utf-8'))

        elif parsed_path.path == '/api/deaddrop/list':
            drops = get_dead_drops()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(drops).encode('utf-8'))

        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), DarkNetHandler) as httpd:
        print(f"[*] DarkNet V2 Node operational on http://localhost:{PORT}")
        httpd.serve_forever()
INNER_EOF

cat << 'INNER_EOF' > darknet_chat_v2/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>DARKNET // V2 SECURE ENCLAVE</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="terminal-container">
        <header class="terminal-header">
            <span class="status-indicator"></span>
            <h1>DARKNET SECURE COMM // PROTOCOL V2</h1>
            <button id="rotate-circuit-btn">ROTATE CIRCUIT</button>
            <span id="node-status">NODES: SECURE</span>
        </header>

        <div class="workspace">
            <div class="sidebar">
                <h2>// RELAY TOPOLOGY</h2>
                <ul id="node-list"></ul>
                
                <h2>// EXPANSIONS</h2>
                <div class="expansion-panel">
                    <h3>DEAD-DROP VAULT</h3>
                    <input type="text" id="drop-recipient" placeholder="Target Hash..." />
                    <textarea id="drop-payload" placeholder="Asynchronous drop payload..."></textarea>
                    <button id="drop-btn">ARM DEAD DROP</button>
                    <div id="drop-log" class="drop-log"></div>
                </div>

                <div class="vault-stats">
                    <p>ENCRYPTION: <strong>AES-256-GCM</strong></p>
                    <p>CIRCUIT MASK: <strong>ACTIVE</strong></p>
                </div>
            </div>

            <div class="chat-main">
                <div id="message-log" class="message-log"></div>

                <div class="transmission-box">
                    <input type="text" id="recipient-input" placeholder="Recipient Onion Hash..." />
                    <select id="burn-timer">
                        <option value="5">Burn: 5s</option>
                        <option value="10" selected>Burn: 10s</option>
                        <option value="30">Burn: 30s</option>
                    </select>
                    <textarea id="payload-input" placeholder="Enter encrypted transmission payload..."></textarea>
                    <button id="transmit-btn">TRANSMIT PAYLOAD</button>
                </div>
            </div>
        </div>
    </div>
    <script src="app.js"></script>
</body>
</html>
INNER_EOF

cat << 'INNER_EOF' > darknet_chat_v2/frontend/style.css
:root {
    --bg-obsidian: #0B0F12;
    --panel-bg: #12181F;
    --gold: #D4AF37;
    --teal: #008080;
    --teal-glow: #00FFFF;
    --text-main: #C0C0C0;
}

body {
    background-color: var(--bg-obsidian);
    color: var(--text-main);
    font-family: 'Courier New', Courier, monospace;
    margin: 0;
    padding: 10px;
}

.terminal-container {
    max-width: 1300px;
    margin: 0 auto;
    border: 1px solid var(--teal);
    background-color: var(--panel-bg);
    box-shadow: 0 0 15px rgba(0, 128, 128, 0.2);
}

.terminal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 15px;
    border-bottom: 1px solid var(--teal);
    background: #0E1319;
    flex-wrap: wrap;
    gap: 8px;
}

.terminal-header h1 {
    font-size: 1rem;
    color: var(--gold);
    margin: 0;
    letter-spacing: 1px;
}

#rotate-circuit-btn {
    background: transparent;
    border: 1px solid var(--gold);
    color: var(--gold);
    padding: 5px 10px;
    cursor: pointer;
    font-family: inherit;
    font-size: 0.75rem;
    transition: background 0.2s;
}

#rotate-circuit-btn:hover {
    background: rgba(212, 175, 55, 0.1);
}

.status-indicator {
    width: 10px;
    height: 10px;
    background-color: var(--teal);
    border-radius: 50%;
    box-shadow: 0 0 8px var(--teal-glow);
}

.workspace {
    display: flex;
    height: 650px;
}

.sidebar {
    width: 320px;
    border-right: 1px solid var(--teal);
    padding: 15px;
    background: #0D1217;
    box-sizing: border-box;
    overflow-y: auto;
}

.sidebar h2 {
    font-size: 0.85rem;
    color: var(--gold);
    margin-top: 10px;
}

#node-list {
    list-style: none;
    padding: 0;
}

#node-list li {
    padding: 6px 8px;
    margin-bottom: 6px;
    border: 1px dashed var(--teal);
    font-size: 0.75rem;
    color: var(--teal-glow);
}

.expansion-panel {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin-top: 10px;
    border: 1px solid rgba(212, 175, 55, 0.3);
    padding: 10px;
    background: #0A0E12;
}

.expansion-panel h3 {
    font-size: 0.75rem;
    color: var(--gold);
    margin: 0 0 5px 0;
}

.expansion-panel input, .expansion-panel textarea {
    background: #090D10;
    border: 1px solid var(--teal);
    color: var(--text-main);
    padding: 6px;
    font-family: inherit;
    font-size: 0.75rem;
}

.expansion-panel textarea {
    height: 40px;
    resize: none;
}

#drop-btn {
    background: var(--teal);
    color: var(--bg-obsidian);
    border: none;
    padding: 6px;
    font-weight: bold;
    cursor: pointer;
    font-size: 0.75rem;
}

.drop-log {
    max-height: 80px;
    overflow-y: auto;
    font-size: 0.7rem;
    color: var(--teal-glow);
    margin-top: 5px;
}

.vault-stats {
    margin-top: 20px;
    font-size: 0.75rem;
    border-top: 1px solid rgba(0, 128, 128, 0.3);
    padding-top: 10px;
}

.chat-main {
    flex: 1;
    display: flex;
    flex-direction: column;
    padding: 15px;
    box-sizing: border-box;
    min-width: 0;
}

.message-log {
    flex: 1;
    overflow-y: auto;
    border: 1px solid rgba(0, 128, 128, 0.4);
    padding: 12px;
    margin-bottom: 12px;
    background: #080B0E;
}

.message-item {
    margin-bottom: 10px;
    padding: 8px;
    border-left: 3px solid var(--gold);
    background: rgba(212, 175, 55, 0.03);
    font-size: 0.8rem;
    word-break: break-all;
}

.message-meta {
    color: var(--teal);
    font-size: 0.7rem;
    margin-bottom: 4px;
}

.transmission-box {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.transmission-box input, .transmission-box select, .transmission-box textarea {
    background: #090D10;
    border: 1px solid var(--teal);
    color: var(--text-main);
    padding: 8px;
    font-family: inherit;
    font-size: 0.9rem;
}

.transmission-box textarea {
    resize: none;
    height: 50px;
}

#transmit-btn {
    background: var(--gold);
    color: var(--bg-obsidian);
    border: none;
    padding: 10px;
    font-weight: bold;
    cursor: pointer;
    letter-spacing: 1px;
    transition: background 0.2s;
}

#transmit-btn:hover {
    background: var(--teal-glow);
}

@media (max-width: 768px) {
    body { padding: 0; }
    .terminal-container { border: none; min-height: 100vh; }
    .workspace { flex-direction: column; height: auto; }
    .sidebar { width: 100%; border-right: none; border-bottom: 1px solid var(--teal); padding: 10px 15px; }
    .vault-stats { display: none; }
    .chat-main { height: calc(100vh - 280px); padding: 10px; }
    .message-log { height: 200px; }
}
INNER_EOF

cat << 'INNER_EOF' > darknet_chat_v2/frontend/app.js
async function fetchNodes() {
    try {
        const res = await fetch('/api/nodes');
        const nodes = await res.json();
        const list = document.getElementById('node-list');
        list.innerHTML = nodes.map(n => `<li>${n.node_id} [${n.latency}]</li>`).join('');
    } catch (err) {
        console.error("Node sync error", err);
    }
}

async function fetchMessages() {
    try {
        const res = await fetch('/api/messages');
        const messages = await res.json();
        const log = document.getElementById('message-log');
        log.innerHTML = messages.map(m => {
            const decoded = atob(m.payload);
            const timeLeft = Math.max(0, Math.floor(m.expires_at - Date.now() / 1000));
            return `
                <div class="message-item">
                    <div class="message-meta">TO: ${m.recipient} | ID: ${m.id} | DESTruct: ${timeLeft}s</div>
                    <div>${decoded}</div>
                </div>
            `;
        }).join('');
    } catch (err) {
        console.error("Message sync error", err);
    }
}

async function fetchDeadDrops() {
    try {
        const res = await fetch('/api/deaddrop/list');
        const drops = await res.json();
        const log = document.getElementById('drop-log');
        log.innerHTML = drops.map(d => `<div>DROP: ${d.drop_id} (${d.recipient})</div>`).join('');
    } catch (err) {
        console.error("Dead drop sync error", err);
    }
}

document.getElementById('transmit-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('recipient-input').value || 'BROADCAST';
    const payload = document.getElementById('payload-input').value;
    const burn_timer = parseInt(document.getElementById('burn-timer').value);

    if (!payload.trim()) return;

    await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, payload, burn_timer })
    });

    document.getElementById('payload-input').value = '';
    fetchMessages();
});

document.getElementById('rotate-circuit-btn').addEventListener('click', async () => {
    await fetch('/api/circuit/rotate', { method: 'POST' });
    fetchNodes();
});

document.getElementById('drop-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('drop-recipient').value || 'SECURE_DROP';
    const payload = document.getElementById('drop-payload').value;

    if (!payload.trim()) return;

    await fetch('/api/deaddrop/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, payload })
    });

    document.getElementById('drop-payload').value = '';
    fetchDeadDrops();
});

setInterval(() => {
    fetchMessages();
    fetchNodes();
    fetchDeadDrops();
}, 2000);

fetchNodes();
fetchMessages();
fetchDeadDrops();
INNER_EOF

echo "[*] Clearing port 8080..."
fuser -k 8080/tcp 2>/dev/null || true
pkill -f "python3 server/server.py" 2>/dev/null || true
sleep 1

echo "[*] Launching DarkNet V2 Server..."
cd darknet_chat_v2
python3 server/server.py
