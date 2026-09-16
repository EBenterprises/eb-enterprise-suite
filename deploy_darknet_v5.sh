#!/bin/bash
echo "[*] Initializing DarkNet Communications Enclave V5 (Zero-Collision Stack)..."
cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not detected. Aborting."
    exit 1
fi

mkdir -p darknet_chat_v5/server darknet_chat_v5/frontend darknet_chat_v5/assets

# Write Cumulative & V5 Expansions Module
cat << 'INNER_EOF' > darknet_chat_v5/server/expansions.py
import time
import os
import base64
import hashlib

DEAD_DROP_VAULT = []
CIRCUIT_LOG = []
ZK_VAULT = []
CRIE_LOG = []

PEER_REGISTRY = [
    {"node_id": "TOR_RELAY_V5_0x9A", "latency": "19ms", "status": "SECURE", "fingerprint": "SHA256:7F9A...3B"},
    {"node_id": "I2P_TUNNEL_V5_0x4F", "latency": "42ms", "status": "ENCRYPTED", "fingerprint": "SHA256:22C4...EE"},
    {"node_id": "DARK_HOP_V5_0x11", "latency": "9ms", "status": "ACTIVE", "fingerprint": "SHA256:88AA...01"},
    {"peer_id": "NODE_ALPHA_V5_0x77", "status": "PEERED", "ping": "7ms", "fingerprint": "SHA256:44B2...FF"}
]

def handle_dead_drop(body_data):
    recipient = body_data.get('recipient', 'UNKNOWN')
    payload = body_data.get('payload', '')
    drop_id = base64.b32encode(os.urandom(4)).decode('utf-8').strip('=')
    drop = {
        "drop_id": drop_id,
        "recipient": recipient,
        "payload": base64.b64encode(payload.encode('utf-8')).decode('utf-8'),
        "retrieved": False,
        "created_at": time.time()
    }
    DEAD_DROP_VAULT.append(drop)
    return {"status": "DEAD_DROP_ARMED", "drop_id": drop_id}

def get_dead_drops():
    return [d for d in DEAD_DROP_VAULT if not d["retrieved"]]

def rotate_circuit():
    nodes = [
        {"node_id": "TOR_EXIT_V5_0x8B", "latency": "21ms", "status": "ROTATED", "fingerprint": "SHA256:33E1...99"},
        {"node_id": "I2P_HOP_V5_0x9C", "latency": "45ms", "status": "SECURE", "fingerprint": "SHA256:66AA...22"},
        {"node_id": "DARK_RELAY_V5_0x33", "latency": "12ms", "status": "ACTIVE", "fingerprint": "SHA256:22CC...88"}
    ]
    CIRCUIT_LOG.append({"timestamp": time.time(), "nodes": nodes})
    return nodes

def cloak_payload(raw_text, mode):
    encoded = base64.b64encode(raw_text.encode('utf-8')).decode('utf-8')
    if mode == "IMAGE_HEADER":
        return f"data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==#payload:{encoded}"
    elif mode == "METADATA_EXIF":
        return f"EXIF:AUTHOR=ANON_V5;COMMENT={encoded}"
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

def run_crie_diagnostics():
    status = {"crie_status": "ONLINE", "self_healing": "ACTIVE", "last_intercept": time.time()}
    CRIE_LOG.append(status)
    return status
INNER_EOF

# Write V5 Server Engine with Dynamic Port Binding & Reusability
cat << 'INNER_EOF' > darknet_chat_v5/server/server.py
import http.server
import socketserver
import json
import os
import time
import base64
from urllib.parse import urlparse
from expansions import (
    handle_dead_drop, get_dead_drops, rotate_circuit, 
    cloak_payload, register_zk_drop, unlock_zk_drop, 
    run_crie_diagnostics, PEER_REGISTRY, ZK_VAULT, DEAD_DROP_VAULT
)

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")
ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../assets")

MESSAGE_VAULT = []
ACTIVE_NODES = [
    {"node_id": "TOR_RELAY_V5_0x9A", "latency": "19ms", "status": "SECURE", "fingerprint": "SHA256:7F9A...3B"},
    {"node_id": "I2P_TUNNEL_V5_0x4F", "latency": "42ms", "status": "ENCRYPTED", "fingerprint": "SHA256:22C4...EE"},
    {"node_id": "DARK_HOP_V5_0x11", "latency": "9ms", "status": "ACTIVE", "fingerprint": "SHA256:88AA...01"}
]

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

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
            self.wfile.write(json.dumps(PEER_REGISTRY + ACTIVE_NODES).encode('utf-8'))

        elif parsed_path.path == '/api/deaddrop/list':
            drops = get_dead_drops()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(drops).encode('utf-8'))

        elif parsed_path.path == '/api/zk/list':
            summary = [{"drop_id": d["drop_id"], "recipient": d["recipient"], "locked": d["locked"]} for d in ZK_VAULT]
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(summary).encode('utf-8'))

        elif parsed_path.path == '/api/crie/status':
            status = run_crie_diagnostics()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(status).encode('utf-8'))

        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    
    # Dynamic Port Fallback to avoid Address Already in Use collisions
    PORT = 8080
    server_instance = None
    for p in range(8080, 8095):
        try:
            server_instance = ReusableTCPServer(("", p), DarkNetHandler)
            PORT = p
            break
        except OSError:
            continue

    if not server_instance:
        print("[!] Error: Could not bind to any port between 8080 and 8094.")
        exit(1)

    print(f"[*] DarkNet V5 Enclave operational on http://localhost:{PORT}")
    try:
        server_instance.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down DarkNet V5 Enclave...")
        server_instance.server_close()
INNER_EOF

# Write V5 Frontend HTML
cat << 'INNER_EOF' > darknet_chat_v5/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>DARKNET // V5 ENCLAVE</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="terminal-container">
        <header class="terminal-header">
            <span class="status-indicator"></span>
            <h1>DARKNET SECURE COMM // PROTOCOL V5</h1>
            <button id="rotate-circuit-btn">ROTATE CIRCUIT</button>
            <span id="crie-status">CRIE: SELF-HEALING ACTIVE</span>
        </header>

        <div class="workspace">
            <div class="sidebar">
                <h2>// RELAY MATRIX & PEERS</h2>
                <ul id="node-list"></ul>
                
                <h2>// EXPANSION 1: DEAD-DROP VAULT</h2>
                <div class="expansion-panel">
                    <h3>ARM DEAD DROP</h3>
                    <input type="text" id="drop-recipient" placeholder="Target Hash..." />
                    <textarea id="drop-payload" placeholder="Asynchronous drop payload..."></textarea>
                    <button id="drop-btn">ARM DROP</button>
                    <div id="drop-log" class="drop-log"></div>
                </div>

                <h2>// EXPANSION 2: ZK LOCKBOX</h2>
                <div class="expansion-panel">
                    <h3>SECURE ZK-VAULT</h3>
                    <input type="text" id="zk-recipient" placeholder="Recipient Hash..." />
                    <input type="password" id="zk-pass" placeholder="Unlock Passphrase..." />
                    <textarea id="zk-payload" placeholder="Encrypted ZK payload..."></textarea>
                    <button id="zk-arm-btn">ARM ZK DROP</button>
                    <div id="zk-log" class="drop-log"></div>
                </div>

                <div class="vault-stats">
                    <p>PROTOCOL: <strong>V5 ZERO-COLLISION</strong></p>
                    <p>PORT BIND: <strong>DYNAMIC FALLBACK</strong></p>
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
                    <button id="transmit-btn">TRANSMIT V5 PAYLOAD</button>
                </div>
            </div>
        </div>
    </div>
    <script src="app.js"></script>
</body>
</html>
INNER_EOF

# Write V5 CSS (Executive Spectrum: Obsidian, Gold, Teal)
cat << 'INNER_EOF' > darknet_chat_v5/frontend/style.css
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
    max-width: 1350px;
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
    height: 700px;
}

.sidebar {
    width: 340px;
    border-right: 1px solid var(--teal);
    padding: 15px;
    background: #0D1217;
    box-sizing: border-box;
    overflow-y: auto;
}

.sidebar h2 {
    font-size: 0.8rem;
    color: var(--gold);
    margin-top: 12px;
}

#node-list {
    list-style: none;
    padding: 0;
}

#node-list li {
    padding: 5px 8px;
    margin-bottom: 5px;
    border: 1px dashed var(--teal);
    font-size: 0.7rem;
    color: var(--teal-glow);
}

.expansion-panel {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin-top: 6px;
    border: 1px solid rgba(212, 175, 55, 0.3);
    padding: 8px;
    background: #0A0E12;
}

.expansion-panel h3 {
    font-size: 0.7rem;
    color: var(--gold);
    margin: 0 0 3px 0;
}

.expansion-panel input, .expansion-panel textarea {
    background: #090D10;
    border: 1px solid var(--teal);
    color: var(--text-main);
    padding: 5px;
    font-family: inherit;
    font-size: 0.7rem;
}

.expansion-panel textarea {
    height: 30px;
    resize: none;
}

#drop-btn, #zk-arm-btn {
    background: var(--teal);
    color: var(--bg-obsidian);
    border: none;
    padding: 5px;
    font-weight: bold;
    cursor: pointer;
    font-size: 0.7rem;
}

.drop-log {
    max-height: 50px;
    overflow-y: auto;
    font-size: 0.65rem;
    color: var(--teal-glow);
    margin-top: 3px;
}

.vault-stats {
    margin-top: 15px;
    font-size: 0.7rem;
    border-top: 1px solid rgba(0, 128, 128, 0.3);
    padding-top: 8px;
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

# Write V5 App JavaScript Logic
cat << 'INNER_EOF' > darknet_chat_v5/frontend/app.js
async function fetchNodes() {
    try {
        const res = await fetch('/api/nodes');
        const nodes = await res.json();
        const list = document.getElementById('node-list');
        list.innerHTML = nodes.map(n => `<li>${n.node_id || n.peer_id} [${n.latency || n.ping}]<br><small>${n.fingerprint || ''}</small></li>`).join('');
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
            const timeLeft = Math.max(0, Math.floor(m.expires_at - Date.now() / 1000));
            let displayVal = m.payload;
            if (m.payload && m.payload.includes('#payload:')) {
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

async function fetchZKList() {
    try {
        const res = await fetch('/api/zk/list');
        const zkDrops = await res.json();
        const log = document.getElementById('zk-log');
        log.innerHTML = zkDrops.map(d => `<div>ZK: ${d.drop_id} [Locked: ${d.locked}]</div>`).join('');
    } catch (err) {
        console.error("ZK sync error", err);
    }
}

async function fetchCRIEStatus() {
    try {
        const res = await fetch('/api/crie/status');
        const status = await res.json();
        document.getElementById('crie-status').innerText = `CRIE: ${status.crie_status} (${status.self_healing})`;
    } catch (err) {
        console.error("CRIE sync error", err);
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
    fetchNodes();
    fetchDeadDrops();
    fetchZKList();
    fetchCRIEStatus();
}, 2000);

fetchNodes();
fetchMessages();
fetchDeadDrops();
fetchZKList();
fetchCRIEStatus();
INNER_EOF

# Launch V5 Server
echo "[*] Launching DarkNet V5 Enclave Server..."
cd darknet_chat_v5
python3 server/server.py
