#!/bin/bash
echo "[*] Initializing DarkNet Communications Enclave V3..."
cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not detected. Aborting."
    exit 1
fi

mkdir -p darknet_chat_v3/server darknet_chat_v3/frontend darknet_chat_v3/assets

# Write V3 Expansions (Stegano & ZK Vault)
cat << 'INNER_EOF' > darknet_chat_v3/server/expansions_v3.py
import time
import os
import base64
import hashlib

ZK_VAULT = []
PEER_REGISTRY = [
    {"peer_id": "NODE_ALPHA_0x77", "status": "PEERED", "ping": "12ms"},
    {"peer_id": "NODE_OMEGA_0x88", "status": "LISTENING", "ping": "34ms"}
]

def cloak_payload(raw_text, mode):
    """Wraps payloads in steganographic or camouflage wrappers."""
    encoded = base64.b64encode(raw_text.encode('utf-8')).decode('utf-8')
    if mode == "IMAGE_HEADER":
        return f"data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==#payload:{encoded}"
    elif mode == "METADATA_EXIF":
        return f"EXIF:AUTHOR=ANON;COMMENT={encoded}"
    return encoded

def register_zk_drop(data):
    recipient = data.get('recipient', 'BROADCAST')
    ciphertext = data.get('ciphertext', '')
    passphrase = data.get('passphrase', '')
    
    pass_hash = hashlib.sha256(passphrase.encode('utf-8')).hexdigest() if passphrase else ""
    drop_id = base64.b32encode(os.urandom(4)).decode('utf-8').strip('=')
    
    drop = {
        "drop_id": drop_id,
        "recipient": recipient,
        "ciphertext": ciphertext,
        "pass_hash": pass_hash,
        "locked": bool(pass_hash),
        "timestamp": time.time()
    }
    ZK_VAULT.append(drop)
    return {"status": "ZK_VAULT_ARMED", "drop_id": drop_id}

def unlock_zk_drop(drop_id, passphrase):
    for drop in ZK_VAULT:
        if drop["drop_id"] == drop_id:
            if drop["locked"]:
                p_hash = hashlib.sha256(passphrase.encode('utf-8')).hexdigest()
                if p_hash == drop["pass_hash"]:
                    return {"status": "UNLOCKED", "ciphertext": drop["ciphertext"]}
                else:
                    return {"status": "ERROR", "message": "INVALID_PASSPHRASE"}
            return {"status": "UNLOCKED", "ciphertext": drop["ciphertext"]}
    return {"status": "ERROR", "message": "DROP_NOT_FOUND"}
INNER_EOF

# Write V3 Server Engine
cat << 'INNER_EOF' > darknet_chat_v3/server/server.py
import http.server
import socketserver
import json
import os
import time
import base64
from urllib.parse import urlparse
from expansions_v3 import cloak_payload, register_zk_drop, unlock_zk_drop, PEER_REGISTRY, ZK_VAULT

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../assets")

MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_V3_0x9A", "latency": "28ms", "status": "SECURE"},
    {"node_id": "I2P_V3_0x4F", "latency": "55ms", "status": "ENCRYPTED"}
]

class DarkNetHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        global ACTIVE_NODES, MESSAGE_VAULT
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
                raw_payload = data.get('payload', '')
                steg_mode = data.get('steg_mode', 'NONE')
                burn_timer = int(data.get('burn_timer', 10))

                cloaked = cloak_payload(raw_payload, steg_mode)

                packet = {
                    "id": base64.b32encode(os.urandom(5)).decode('utf-8').strip('='),
                    "recipient": recipient,
                    "payload": cloaked,
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

        elif parsed_path.path == '/api/zk/create':
            res = register_zk_drop(data)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(res).encode('utf-8'))

        elif parsed_path.path == '/api/zk/unlock':
            res = unlock_zk_drop(data.get('drop_id'), data.get('passphrase', ''))
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(res).encode('utf-8'))

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
            self.wfile.write(json.dumps(PEER_REGISTRY).encode('utf-8'))

        elif parsed_path.path == '/api/zk/list':
            summary = [{"drop_id": d["drop_id"], "recipient": d["recipient"], "locked": d["locked"]} for d in ZK_VAULT]
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(summary).encode('utf-8'))

        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), DarkNetHandler) as httpd:
        print(f"[*] DarkNet V3 Node operational on http://localhost:{PORT}")
        httpd.serve_forever()
INNER_EOF

# Write V3 Frontend HTML
cat << 'INNER_EOF' > darknet_chat_v3/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>DARKNET // V3 ENCLAVE</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="terminal-container">
        <header class="terminal-header">
            <span class="status-indicator"></span>
            <h1>DARKNET SECURE COMM // PROTOCOL V3</h1>
            <span id="node-status">PEERS: SYNCHRONIZED</span>
        </header>

        <div class="workspace">
            <div class="sidebar">
                <h2>// P2P PEER REGISTRY</h2>
                <ul id="peer-list"></ul>
                
                <h2>// ZK-VAULT EXPANSION</h2>
                <div class="expansion-panel">
                    <h3>SECURE LOCKBOX</h3>
                    <input type="text" id="zk-recipient" placeholder="Recipient Hash..." />
                    <input type="password" id="zk-pass" placeholder="Unlock Passphrase..." />
                    <textarea id="zk-payload" placeholder="Encrypted payload..."></textarea>
                    <button id="zk-arm-btn">ARM ZK DROP</button>
                    <div id="zk-log" class="drop-log"></div>
                </div>

                <div class="vault-stats">
                    <p>PROTOCOL: <strong>V3 STEGANO-P2P</strong></p>
                    <p>SHIELD: <strong>ACTIVE</strong></p>
                </div>
            </div>

            <div class="chat-main">
                <div id="message-log" class="message-log"></div>

                <div class="transmission-box">
                    <input type="text" id="recipient-input" placeholder="Recipient Onion Hash..." />
                    <div class="controls-row">
                        <select id="steg-mode">
                            <option value="NONE">Stegano: None</option>
                            <option value="IMAGE_HEADER">Stegano: Image Wrapper</option>
                            <option value="METADATA_EXIF">Stegano: EXIF Meta</option>
                        </select>
                        <select id="burn-timer">
                            <option value="5">Burn: 5s</option>
                            <option value="10" selected>Burn: 10s</option>
                            <option value="30">Burn: 30s</option>
                        </select>
                    </div>
                    <textarea id="payload-input" placeholder="Enter transmission payload..."></textarea>
                    <button id="transmit-btn">TRANSMIT V3 PAYLOAD</button>
                </div>
            </div>
        </div>
    </div>
    <script src="app.js"></script>
</body>
</html>
INNER_EOF

# Write V3 CSS (Executive Spectrum: Obsidian, Gold, Teal)
cat << 'INNER_EOF' > darknet_chat_v3/frontend/style.css
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

#peer-list {
    list-style: none;
    padding: 0;
}

#peer-list li {
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
    height: 35px;
    resize: none;
}

#zk-arm-btn {
    background: var(--teal);
    color: var(--bg-obsidian);
    border: none;
    padding: 6px;
    font-weight: bold;
    cursor: pointer;
    font-size: 0.75rem;
}

.drop-log {
    max-height: 70px;
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

.controls-row {
    display: flex;
    gap: 8px;
}

.controls-row select {
    flex: 1;
}

.transmission-box input, .transmission-box select, .transmission-box textarea {
    background: #090D10;
    border: 1px solid var(--teal);
    color: var(--text-main);
    padding: 8px;
    font-family: inherit;
    font-size: 0.85rem;
}

.transmission-box textarea {
    resize: none;
    height: 45px;
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
    .message-log { height: 180px; }
}
INNER_EOF

# Write V3 Client Logic
cat << 'INNER_EOF' > darknet_chat_v3/frontend/app.js
async function fetchPeers() {
    try {
        const res = await fetch('/api/nodes');
        const peers = await res.json();
        const list = document.getElementById('peer-list');
        list.innerHTML = peers.map(p => `<li>${p.peer_id} [${p.ping}]</li>`).join('');
    } catch (err) {
        console.error("Peer sync error", err);
    }
}

async function fetchMessages() {
    try {
        const res = await fetch('/api/messages');
        const messages = await res.json();
        const log = document.getElementById('message-log');
        log.innerHTML = messages.map(m => {
            const timeLeft = Math.max(0, Math.floor(m.expires_at - Date.now() / 1000));
            let displayVal = m.payload;
            if (m.payload.includes('#payload:')) {
                const parts = m.payload.split('#payload:');
                try { displayVal = `[STEGANO CLOAKED] -> ${atob(parts[1])}`; } catch(e) {}
            }
            return `
                <div class="message-item">
                    <div class="message-meta">TO: ${m.recipient} | ID: ${m.id} | DESTruct: ${timeLeft}s</div>
                    <div>${displayVal}</div>
                </div>
            `;
        }).join('');
    } catch (err) {
        console.error("Message sync error", err);
    }
}

async function fetchZKList() {
    try {
        const res = await fetch('/api/zk/list');
        const zkDrops = await res.json();
        const log = document.getElementById('zk-log');
        log.innerHTML = zkDrops.map(d => `<div>ZK-DROP: ${d.drop_id} [Locked: ${d.locked}]</div>`).join('');
    } catch (err) {
        console.error("ZK sync error", err);
    }
}

document.getElementById('transmit-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('recipient-input').value || 'BROADCAST';
    const payload = document.getElementById('payload-input').value;
    const steg_mode = document.getElementById('steg-mode').value;
    const burn_timer = parseInt(document.getElementById('burn-timer').value);

    if (!payload.trim()) return;

    await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, payload, steg_mode, burn_timer })
    });

    document.getElementById('payload-input').value = '';
    fetchMessages();
});

document.getElementById('zk-arm-btn').addEventListener('click', async () => {
    const recipient = document.getElementById('zk-recipient').value || 'SECURE_ZK';
    const passphrase = document.getElementById('zk-pass').value;
    const ciphertext = document.getElementById('zk-payload').value;

    if (!ciphertext.trim()) return;

    await fetch('/api/zk/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recipient, passphrase, ciphertext })
    });

    document.getElementById('zk-payload').value = '';
    document.getElementById('zk-pass').value = '';
    fetchZKList();
});

setInterval(() => {
    fetchMessages();
    fetchPeers();
    fetchZKList();
}, 2000);

fetchPeers();
fetchMessages();
fetchZKList();
INNER_EOF

# Clear port 8080 and launch V3
echo "[*] Clearing port 8080..."
fuser -k 8080/tcp 2>/dev/null || true
pkill -f "python3 server/server.py" 2>/dev/null || true
sleep 1

echo "[*] Launching DarkNet V3 Enclave Server..."
cd darknet_chat_v3
python3 server/server.py
