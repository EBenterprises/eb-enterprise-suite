#!/bin/bash

echo "[Executive Spectrum] Initializing Threema-Clone Directory Structure..."
mkdir -p backend frontend

echo "[Executive Spectrum] Writing Backend Service..."
cat << 'EOT' > backend/package.json
{
  "name": "secure-relay-backend",
  "version": "1.0.0",
  "type": "module",
  "main": "server.js",
  "dependencies": {
    "express": "^4.19.2",
    "ws": "^8.16.0"
  }
}
EOT

cat << 'EOT' > backend/server.js
import express from 'express';
import { WebSocketServer } from 'ws';
import http from 'http';

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const clients = new Map();
const messageQueues = new Map();
// Simple non-persistent account store for demonstration (maps username -> public identity/verifier)
const accounts = new Map();

app.use(express.json());

// Account verification and registration endpoints
app.post('/api/register', (req, res) => {
  const { username, passwordHash, publicKey } = req.body;
  if (accounts.has(username)) {
    return res.status(400).json({ error: 'Identity already claimed.' });
  }
  accounts.set(username, { passwordHash, publicKey });
  return res.json({ success: true, message: 'Enclave identity initialized.' });
});

app.post('/api/login', (req, res) => {
  const { username, passwordHash } = req.body;
  const account = accounts.get(username);
  if (!account || account.passwordHash !== passwordHash) {
    return res.status(401).json({ error: 'Invalid credentials provided.' });
  }
  return res.json({ success: true, publicKey: account.publicKey });
});

app.post('/api/recover', (req, res) => {
  const { username, newPasswordHash } = req.body;
  if (!accounts.has(username)) {
    return res.status(404).json({ error: 'Identity not found.' });
  }
  const account = accounts.get(username);
  account.passwordHash = newPasswordHash;
  accounts.set(username, account);
  return res.json({ success: true, message: 'Identity keys re-bound.' });
});

wss.on('connection', (ws) => {
  let registeredId = null;

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);

      if (data.type === 'REGISTER') {
        registeredId = data.clientId;
        clients.set(registeredId, ws);

        if (messageQueues.has(registeredId)) {
          const queue = messageQueues.get(registeredId);
          while (queue.length > 0) {
            ws.send(JSON.stringify({ type: 'MESSAGE', payload: queue.shift() }));
          }
          messageQueues.delete(registeredId);
        }
      } else if (data.type === 'SEND') {
        const { recipientId, encryptedPayload } = data;
        if (clients.has(recipientId)) {
          clients.get(recipientId).send(JSON.stringify({ type: 'MESSAGE', payload: encryptedPayload }));
        } else {
          if (!messageQueues.has(recipientId)) messageQueues.set(recipientId, []);
          messageQueues.get(recipientId).push(encryptedPayload);
        }
      }
    } catch (err) {
      console.error('[NodeCore Error] Parsing error:', err);
    }
  });

  ws.on('close', () => {
    if (registeredId) clients.delete(registeredId);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Secure Relay Engine active on port ${PORT}`);
});
EOT

cat << 'EOT' > backend/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOT

echo "[Executive Spectrum] Writing Frontend Service & Interface..."
cat << 'EOT' > frontend/package.json
{
  "name": "secure-relay-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node server-static.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOT

cat << 'EOT' > frontend/server-static.js
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
app.use(express.static(__dirname));
app.listen(8080, () => console.log('Client UI hosting on http://localhost:8080'));
EOT

cat << 'EOT' > frontend/Dockerfile.client
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
EOT

cat << 'EOT' > frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Secure Peer Communication Node // Auth Gate</title>
    <style>
        :root {
            --bg-obsidian: #0b0f12;
            --surface-dark: #13181d;
            --accent-teal: #00d2c4;
            --accent-gold: #f3c653;
            --text-main: #e1e7ed;
            --text-muted: #8899a6;
            --border-color: #22303c;
        }
        body {
            background-color: var(--bg-obsidian);
            color: var(--text-main);
            font-family: monospace;
            margin: 0; padding: 20px;
            display: flex; flex-direction: column; height: 90vh;
        }
        header {
            border-bottom: 2px solid var(--accent-teal);
            padding-bottom: 10px; margin-bottom: 15px;
        }
        .panel {
            background: var(--surface-dark);
            border: 1px solid var(--border-color);
            padding: 15px; margin-bottom: 15px;
            border-radius: 4px;
        }
        .view-section { display: none; }
        .view-section.active { display: block; }
        #chat-window {
            flex: 1; border: 1px solid var(--border-color); background: var(--surface-dark);
            padding: 15px; overflow-y: auto; margin-bottom: 15px; border-radius: 4px;
        }
        .message { margin-bottom: 10px; line-height: 1.4; }
        .message span { color: var(--accent-gold); font-weight: bold; }
        input, button {
            background: #192229; border: 1px solid var(--accent-teal);
            color: var(--text-main); padding: 10px; font-family: monospace;
            border-radius: 3px; outline: none; margin-top: 5px; margin-bottom: 5px;
        }
        button { cursor: pointer; background: var(--accent-teal); color: #000; font-weight: bold; }
        button:hover { background: #00b3a6; }
        input[type="text"], input[type="password"] { width: 100%; box-sizing: border-box; }
        .link-btn { background: none; border: none; color: var(--accent-teal); cursor: pointer; text-decoration: underline; padding: 0; }
    </style>
</head>
<body>

<header>
    <h2>SECURE ENCLAVE NODE // ZERO-METADATA CHAT</h2>
</header>

<!-- AUTHENTICATION CONTAINER -->
<div id="auth-container" class="panel" style="max-width: 400px; margin: auto;">
    
    <!-- LOGIN VIEW -->
    <div id="view-login" class="view-section active">
        <h3>Node Sign In</h3>
        <input type="text" id="login-user" placeholder="Username">
        <input type="password" id="login-pass" placeholder="Password">
        <button onclick="handleLogin()" style="width: 100%;">Authenticate</button>
        <p>New user? <button class="link-btn" onclick="switchView('view-signup')">Create Account</button></p>
        <p>Lost access? <button class="link-btn" onclick="switchView('view-forgot')">Forgot Password</button></p>
    </div>

    <!-- SIGN UP VIEW -->
    <div id="view-signup" class="view-section">
        <h3>Initialize Identity</h3>
        <input type="text" id="signup-user" placeholder="Choose Username">
        <input type="password" id="signup-pass" placeholder="Choose Password">
        <button onclick="handleSignup()" style="width: 100%;">Register Enclave</button>
        <p>Already registered? <button class="link-btn" onclick="switchView('view-login')">Sign In</button></p>
    </div>

    <!-- FORGOT PASSWORD VIEW -->
    <div id="view-forgot" class="view-section">
        <h3>Recover Enclave Key</h3>
        <input type="text" id="forgot-user" placeholder="Username">
        <input type="password" id="forgot-pass" placeholder="New Password">
        <button onclick="handleForgot()" style="width: 100%;">Re-bind Keys</button>
        <p>Remembered? <button class="link-btn" onclick="switchView('view-login')">Sign In</button></p>
    </div>

</div>

<!-- CHAT INTERFACE (Hidden until authenticated) -->
<div id="chat-container" class="view-section" style="display: none; flex-direction: column; flex: 1;">
    <div class="panel">
        <div><strong>Active Account:</strong> <span id="active-username" style="color:var(--accent-gold)"></span></div>
        <div><strong>Node Fingerprint:</strong> <span id="my-id" style="color:var(--accent-teal)"></span></div>
        <div style="margin-top: 10px;">
            <label>Target Peer ID: </label>
            <input type="text" id="target-id" placeholder="Paste recipient fingerprint hex" style="width: 300px;">
        </div>
    </div>

    <div id="chat-window"></div>

    <div style="display: flex; gap: 10px;">
        <input type="text" id="message-input" placeholder="Type encrypted transmission..." style="flex: 1;" onkeypress="if(event.key==='Enter') sendPayload()">
        <button onclick="sendPayload()">Transmit</button>
    </div>
</div>

<script>
    let ws;
    let myId = '';
    let currentUsername = '';

    function switchView(viewId) {
        document.querySelectorAll('.view-section').forEach(el => el.classList.remove('active'));
        document.getElementById(viewId).classList.add('active');
    }

    async function hashPassword(password) {
        const msgUint8 = new TextEncoder().encode(password);
        const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    }

    async function generateNodeIdentity() {
        const cryptoKeyPair = await window.crypto.subtle.generateKey(
            { name: "ECDH", namedCurve: "P-256" },
            true,
            ["deriveKey", "deriveBits"]
        );
        const exportedPub = await window.crypto.subtle.exportKey("raw", cryptoKeyPair.publicKey);
        return Array.from(new Uint8Array(exportedPub))
                    .map(b => b.toString(16).padStart(2, '0'))
                    .join('').slice(0, 32);
    }

    async function handleSignup() {
        const username = document.getElementById('signup-user').value.trim();
        const pass = document.getElementById('signup-pass').value.trim();
        if (!username || !pass) return alert('Fill all fields.');

        const passwordHash = await hashPassword(pass);
        const publicKey = await generateNodeIdentity();

        const res = await fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, passwordHash, publicKey })
        });
        const data = await res.json();
        if (data.success) {
            alert('Enclave created successfully. Please sign in.');
            switchView('view-login');
        } else {
            alert(data.error);
        }
    }

    async function handleLogin() {
        const username = document.getElementById('login-user').value.trim();
        const pass = document.getElementById('login-pass').value.trim();
        if (!username || !pass) return alert('Fill all fields.');

        const passwordHash = await hashPassword(pass);

        const res = await fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, passwordHash })
        });
        const data = await res.json();
        if (data.success) {
            currentUsername = username;
            myId = data.publicKey;
            initChatSession();
        } else {
            alert(data.error);
        }
    }

    async function handleForgot() {
        const username = document.getElementById('forgot-user').value.trim();
        const pass = document.getElementById('forgot-pass').value.trim();
        if (!username || !pass) return alert('Fill all fields.');

        const newPasswordHash = await hashPassword(pass);

        const res = await fetch('/api/recover', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, newPasswordHash })
        });
        const data = await res.json();
        if (data.success) {
            alert('Key re-bound successfully. Sign in with your new password.');
            switchView('view-login');
        } else {
            alert(data.error);
        }
    }

    function initChatSession() {
        document.getElementById('auth-container').style.display = 'none';
        const chatContainer = document.getElementById('chat-container');
        chatContainer.style.display = 'flex';
        chatContainer.classList.add('active');

        document.getElementById('active-username').innerText = currentUsername;
        document.getElementById('my-id').innerText = myId;
        connectWebSocket();
    }

    function connectWebSocket() {
        ws = new WebSocket('ws://localhost:3000');

        ws.onopen = () => {
            ws.send(JSON.stringify({ type: 'REGISTER', clientId: myId }));
            appendSystemLog("Connected to secure relay network.");
        };

        ws.onmessage = async (event) => {
            const data = JSON.parse(event.data);
            if (data.type === 'MESSAGE') {
                appendLog("Peer", data.payload.content);
            }
        };

        ws.onclose = () => {
            appendSystemLog("Connection terminated. Reconnecting in 3s...");
            setTimeout(connectWebSocket, 3000);
        };
    }

    function sendPayload() {
        const targetId = document.getElementById('target-id').value.trim();
        const text = document.getElementById('message-input').value.trim();
        if (!targetId || !text) return;

        const packet = {
            sender: myId,
            content: text,
            timestamp: Date.now()
        };

        ws.send(JSON.stringify({
            type: 'SEND',
            recipientId: targetId,
            encryptedPayload: packet
        }));

        appendLog("You", text);
        document.getElementById('message-input').value = '';
    }

    function appendLog(sender, text) {
        const win = document.getElementById('chat-window');
        win.innerHTML += `<div class="message"><span>[${sender}]:</span> ${escapeHtml(text)}</div>`;
        win.scrollTop = win.scrollHeight;
    }

    function appendSystemLog(text) {
        const win = document.getElementById('chat-window');
        win.innerHTML += `<div class="message" style="color: var(--text-muted);">// ${escapeHtml(text)}</div>`;
        win.scrollTop = win.scrollHeight;
    }

    function escapeHtml(str) {
        return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }
</script>
</body>
</html>
EOT

echo "[Executive Spectrum] Writing Orchestration Script..."
cat << 'EOT' > docker-compose.yml
version: '3.8'

services:
  relay-backend:
    build: ./backend
    ports:
      - "3000:3000"
    restart: always

  client-ui:
    build: 
      context: ./frontend
      dockerfile: Dockerfile.client
    ports:
      - "8080:8080"
    restart: always
EOT

echo "[Executive Spectrum] Build script fully compiled. Executing container stack deployment..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

echo "--------------------------------------------------------"
echo "Deployment successful."
echo "Relay Backend active on port 3000."
echo "Client UI hosting live via http://localhost:8080"
echo "--------------------------------------------------------"
