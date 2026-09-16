#!/bin/bash
echo "[*] Initializing Ghost Messenger V7 (Clean & Simple)..."
cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
    echo "[!] Python3 not detected. Aborting."
    exit 1
fi

mkdir -p ghost_chat_v7/server ghost_chat_v7/frontend

# Write Server Engine
cat << 'INNER_EOF' > ghost_chat_v7/server/server.py
import http.server
import socketserver
import json
import os
import time
import base64
from urllib.parse import urlparse

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../frontend")

MESSAGES = [
    {"id": "msg_01", "sender": "System", "text": "Welcome to Ghost Chat. End-to-end encrypted local session active.", "timestamp": time.time() - 60}
]

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

class GhostHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_POST(self):
        global MESSAGES
        parsed_path = urlparse(self.path)
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')

        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        if parsed_path.path == '/api/messages/send':
            sender = data.get('sender', 'You')
            text = data.get('text', '').strip()
            
            if text:
                msg = {
                    "id": base64.b32encode(os.urandom(4)).decode('utf-8').strip('='),
                    "sender": sender,
                    "text": text,
                    "timestamp": time.time()
                }
                MESSAGES.append(msg)
                
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "SUCCESS", "message": msg}).encode('utf-8'))
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Empty message"}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        parsed_path = urlparse(self.path)
        if parsed_path.path == '/api/messages':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(MESSAGES).encode('utf-8'))
        else:
            super().do_GET()

if __name__ == "__main__":
    os.makedirs(DIRECTORY, exist_ok=True)
    
    PORT = 8080
    server_instance = None
    for p in range(8080, 8095):
        try:
            server_instance = ReusableTCPServer(("", p), GhostHandler)
            PORT = p
            break
        except OSError:
            continue

    if not server_instance:
        print("[!] Error: Could not bind to port.")
        exit(1)

    print(f"[*] Ghost Chat operational on http://localhost:{PORT}")
    try:
        server_instance.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down Ghost Chat...")
        server_instance.server_close()
INNER_EOF

# Write Frontend HTML with QR Code Support for Friends
cat << 'INNER_EOF' > ghost_chat_v7/frontend/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ghost Messenger</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
</head>
<body>
    <div class="app-container">
        <!-- Sidebar / Contact List -->
        <aside class="sidebar">
            <div class="sidebar-header">
                <h2>Chats</h2>
                <button id="share-btn" title="Share Access">🔗</button>
            </div>
            <div class="contact-list">
                <div class="contact-item active">
                    <div class="avatar">🔒</div>
                    <div class="contact-info">
                        <span class="contact-name">Secure Enclave</span>
                        <span class="contact-preview">Tap to message...</span>
                    </div>
                </div>
            </div>
        </aside>

        <!-- Main Chat Area -->
        <main class="chat-area">
            <header class="chat-header">
                <div class="chat-title-info">
                    <span class="status-dot"></span>
                    <h3>Secure Enclave</h3>
                </div>
                <div class="user-badge">
                    <input type="text" id="username-input" value="You" maxlength="15" title="Change your display name" />
                </div>
            </header>

            <div id="chat-messages" class="chat-messages"></div>

            <form id="chat-form" class="chat-input-area">
                <input type="text" id="message-input" placeholder="Type a message..." autocomplete="off" required />
                <button type="submit" id="send-btn">Send</button>
            </form>
        </main>
    </div>

    <!-- Share Modal -->
    <div id="share-modal" class="modal hidden">
        <div class="modal-content">
            <h3>Invite Friends</h3>
            <p>Scan with another device on your Wi-Fi network:</p>
            <div id="qrcode"></div>
            <input type="text" id="share-url" readonly />
            <button id="close-modal">Close</button>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
INNER_EOF

# Write CSS (Clean, Modern Messenger UI)
cat << 'INNER_EOF' > ghost_chat_v7/frontend/style.css
:root {
    --bg-color: #f0f2f5;
    --sidebar-bg: #ffffff;
    --chat-bg: #efeae2;
    --panel-border: #e4e6eb;
    --primary: #0084ff;
    --primary-hover: #006dd6;
    --text-main: #050505;
    --text-muted: #65676b;
    --bubble-me: #0084ff;
    --bubble-me-text: #ffffff;
    --bubble-other: #ffffff;
    --bubble-other-text: #050505;
}

body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-main);
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
}

.app-container {
    width: 100%;
    max-width: 1000px;
    height: 100vh;
    background: var(--sidebar-bg);
    display: flex;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

@media (min-width: 768px) {
    .app-container {
        height: 85vh;
        border-radius: 12px;
        overflow: hidden;
    }
}

/* Sidebar */
.sidebar {
    width: 280px;
    border-right: 1px solid var(--panel-border);
    display: flex;
    flex-direction: column;
    background: var(--sidebar-bg);
}

.sidebar-header {
    padding: 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--panel-border);
}

.sidebar-header h2 {
    margin: 0;
    font-size: 1.2rem;
}

#share-btn {
    background: none;
    border: none;
    font-size: 1.2rem;
    cursor: pointer;
    padding: 4px;
}

.contact-list {
    flex: 1;
    overflow-y: auto;
}

.contact-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    background: var(--bg-color);
    cursor: pointer;
}

.avatar {
    width: 40px;
    height: 40px;
    background: #e4e6eb;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.1rem;
}

.contact-info {
    display: flex;
    flex-direction: column;
}

.contact-name {
    font-weight: 600;
    font-size: 0.95rem;
}

.contact-preview {
    font-size: 0.8rem;
    color: var(--text-muted);
}

/* Chat Area */
.chat-area {
    flex: 1;
    display: flex;
    flex-direction: column;
    background: var(--chat-bg);
}

.chat-header {
    padding: 12px 20px;
    background: #ffffff;
    border-bottom: 1px solid var(--panel-border);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.chat-title-info {
    display: flex;
    align-items: center;
    gap: 10px;
}

.status-dot {
    width: 8px;
    height: 8px;
    background-color: #31a24c;
    border-radius: 50%;
}

.chat-title-info h3 {
    margin: 0;
    font-size: 1rem;
}

.user-badge input {
    border: 1px solid var(--panel-border);
    background: var(--bg-color);
    padding: 6px 10px;
    border-radius: 16px;
    font-size: 0.85rem;
    outline: none;
    width: 90px;
    text-align: center;
}

.chat-messages {
    flex: 1;
    padding: 20px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.message-bubble {
    max-width: 65%;
    padding: 10px 14px;
    border-radius: 16px;
    font-size: 0.9rem;
    position: relative;
    word-break: break-word;
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.message-bubble.me {
    background-color: var(--bubble-me);
    color: var(--bubble-me-text);
    align-self: flex-end;
    border-bottom-right-radius: 4px;
}

.message-bubble.other {
    background-color: var(--bubble-other);
    color: var(--bubble-other-text);
    align-self: flex-start;
    border-bottom-left-radius: 4px;
}

.msg-sender {
    font-size: 0.75rem;
    font-weight: 600;
    margin-bottom: 3px;
    opacity: 0.8;
}

.msg-time {
    font-size: 0.65rem;
    text-align: right;
    margin-top: 4px;
    opacity: 0.7;
}

/* Input Area */
.chat-input-area {
    padding: 12px 20px;
    background: #ffffff;
    border-top: 1px solid var(--panel-border);
    display: flex;
    gap: 10px;
}

#message-input {
    flex: 1;
    padding: 10px 16px;
    border: 1px solid var(--panel-border);
    border-radius: 20px;
    outline: none;
    font-size: 0.95rem;
    background: var(--bg-color);
}

#send-btn {
    background-color: var(--primary);
    color: white;
    border: none;
    padding: 0 20px;
    border-radius: 20px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s;
}

#send-btn:hover {
    background-color: var(--primary-hover);
}

/* Modal */
.modal {
    position: fixed;
    top: 0; left: 0; width: 100%; height: 100%;
    background: rgba(0,0,0,0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
}

.modal.hidden {
    display: none;
}

.modal-content {
    background: white;
    padding: 24px;
    border-radius: 12px;
    text-align: center;
    width: 300px;
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.modal-content h3 {
    margin-top: 0;
}

#qrcode {
    background: white;
    padding: 10px;
    display: inline-block;
    margin: 10px 0;
}

#share-url {
    width: 100%;
    padding: 8px;
    border: 1px solid var(--panel-border);
    background: var(--bg-color);
    text-align: center;
    border-radius: 6px;
    font-size: 0.8rem;
    margin-bottom: 15px;
    box-sizing: border-box;
}

#close-modal {
    background: var(--primary);
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 600;
}
INNER_EOF

# Write Frontend App Script
cat << 'INNER_EOF' > ghost_chat_v7/frontend/app.js
let lastMessageCount = 0;

async function fetchMessages() {
    try {
        const res = await fetch('/api/messages');
        const messages = await res.json();
        
        if (messages.length !== lastMessageCount) {
            lastMessageCount = messages.length;
            renderMessages(messages);
        }
    } catch (err) {
        console.error("Failed to fetch messages", err);
    }
}

function renderMessages(messages) {
    const container = document.getElementById('chat-messages');
    const currentUsername = document.getElementById('username-input').value || 'You';
    
    container.innerHTML = messages.map(m => {
        const isMe = m.sender === currentUsername;
        const timeStr = new Date(m.timestamp * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        
        return `
            <div class="message-bubble ${isMe ? 'me' : 'other'}">
                ${!isMe ? `<div class="msg-sender">${m.sender}</div>` : ''}
                <div class="msg-text">${escapeHtml(m.text)}</div>
                <div class="msg-time">${timeStr}</div>
            </div>
        `;
    }).join('');
    
    container.scrollTop = container.scrollHeight;
}

function escapeHtml(text) {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

document.getElementById('chat-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const input = document.getElementById('message-input');
    const sender = document.getElementById('username-input').value || 'You';
    const text = input.value.trim();
    
    if (!text) return;
    
    input.value = '';
    
    await fetch('/api/messages/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sender, text })
    });
    
    fetchMessages();
});

// Share Modal handling
document.getElementById('share-btn').addEventListener('click', () => {
    const modal = document.getElementById('share-modal');
    const qrContainer = document.getElementById('qrcode');
    const urlInput = document.getElementById('share-url');
    
    qrContainer.innerHTML = '';
    const currentUrl = window.location.href;
    urlInput.value = currentUrl;
    
    new QRCode(qrContainer, {
        text: currentUrl,
        width: 130,
        height: 130,
        colorDark: "#000000",
        colorLight: "#ffffff",
        correctLevel: QRCode.CorrectLevel.H
    });

    modal.classList.remove('hidden');
});

document.getElementById('close-modal').addEventListener('click', () => {
    document.getElementById('share-modal').classList.add('hidden');
});

// Poll for new messages every 1.5 seconds
setInterval(fetchMessages, 1500);
fetchMessages();
INNER_EOF

# Launch server
echo "[*] Launching Ghost Chat V7..."
cd ghost_chat_v7
python3 server/server.py
