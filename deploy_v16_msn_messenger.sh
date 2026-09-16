#!/usr/bin/env bash
set -euo pipefail

APP_DIR="auth_system"
mkdir -p "$APP_DIR/assets/css"
mkdir -p "$APP_DIR/assets/js"

echo "==> Clearing background processes..."
pkill -f "python3.*server.py" || true
pkill -f "python3 -m http.server" || true
fuser -k 8080/tcp || true

echo "==> Updating Data Engine (Multi-User Persistence, Direct Messaging & Persistence)..."
cat <<'JSEOF' > "$APP_DIR/assets/js/store.js"
const AuthStore = {
  USERS_KEY: 'eb_msn_users',
  SESSION_KEY: 'eb_msn_session',
  CONVERSATIONS_KEY: 'eb_msn_conversations',

  getUsers: () => JSON.parse(localStorage.getItem(AuthStore.USERS_KEY) || '[]'),
  saveUsers: (users) => localStorage.setItem(AuthStore.USERS_KEY, JSON.stringify(users)),

  getConversations: () => JSON.parse(localStorage.getItem(AuthStore.CONVERSATIONS_KEY) || '{}'),
  saveConversations: (convs) => localStorage.setItem(AuthStore.CONVERSATIONS_KEY, JSON.stringify(convs)),

  register: (identity, password, type) => {
    const users = AuthStore.getUsers();
    if (users.find(u => u.identity.toLowerCase() === identity.toLowerCase())) {
      return { success: false, message: 'Identity already registered.' };
    }
    const newUser = { id: 'usr_' + Date.now(), identity, password, type, status: 'Online', customStatus: 'Available' };
    users.push(newUser);
    AuthStore.saveUsers(users);
    return { success: true };
  },

  login: (identity, password) => {
    const users = AuthStore.getUsers();
    const user = users.find(u => u.identity.toLowerCase() === identity.toLowerCase() && u.password === password);
    if (!user) return { success: false, message: 'Invalid credentials.' };
    
    localStorage.setItem(AuthStore.SESSION_KEY, JSON.stringify({
      id: user.id,
      identity: user.identity,
      type: user.type
    }));
    return { success: true };
  },

  getSession: () => JSON.parse(localStorage.getItem(AuthStore.SESSION_KEY) || 'null'),
  clearSession: () => localStorage.removeItem(AuthStore.SESSION_KEY),

  getConvId: (userA, userB) => [userA, userB].sort().join('::'),

  getMessages: (userA, userB) => {
    const convs = AuthStore.getConversations();
    const convId = AuthStore.getConvId(userA, userB);
    return convs[convId] || [];
  },

  sendMessage: (sender, recipient, text) => {
    const convs = AuthStore.getConversations();
    const convId = AuthStore.getConvId(sender, recipient);
    if (!convs[convId]) convs[convId] = [];

    const msg = {
      id: 'msg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 4),
      sender,
      recipient,
      text,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    convs[convId].push(msg);
    AuthStore.saveConversations(convs);
    return msg;
  }
};
JSEOF

echo "==> Overhauling Stylesheet for Executive Pocket MSN Layout..."
cat <<'CSSEOF' > "$APP_DIR/assets/css/style.css"
:root {
  --bg-obsidian: #0b0e14;
  --panel-bg: #11151c;
  --gold-primary: #d4af37;
  --gold-hover: #f1c40f;
  --teal-accent: #008080;
  --teal-bright: #20b2aa;
  --text-main: #e2e8f0;
  --text-muted: #8b98a5;
  --border-color: #1e2638;
  --error-color: #ef4444;
  --success-color: #10b981;
  --bubble-incoming: #171d29;
  --bubble-outgoing: #d4af37;
}

*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, monospace;
  word-wrap: break-word;
  overflow-wrap: anywhere;
}

body {
  background-color: var(--bg-obsidian);
  color: var(--text-main);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

header {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.25rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
}

header.no-nav nav {
  display: none !important;
}

.brand {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--gold-primary);
  letter-spacing: 1.5px;
  text-decoration: none;
  text-transform: uppercase;
}

nav {
  display: flex;
  gap: 1.25rem;
  align-items: center;
}

nav a {
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.9rem;
  font-weight: 500;
  transition: color 0.2s ease;
}

nav a:hover, nav a.active {
  color: var(--teal-bright);
}

main.page-layout {
  flex: 1;
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
  padding: 2.5rem 1.5rem;
  display: flex;
  flex-direction: column;
}

main.page-layout.wide {
  max-width: 1200px;
  padding: 1.5rem;
}

/* --- MSN Pocket Stage --- */
.msn-stage {
  display: grid;
  grid-template-columns: 320px 1fr;
  height: 75vh;
  min-height: 550px;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  background-color: var(--panel-bg);
  overflow: hidden;
}

.msn-contact-pane {
  border-right: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  background-color: #0e121a;
}

.msn-user-card {
  padding: 1.25rem;
  border-bottom: 1px solid var(--border-color);
  background-color: #121722;
}

.msn-user-card .identity {
  font-weight: 700;
  color: var(--gold-primary);
  font-size: 1rem;
}

.msn-user-card .status {
  font-size: 0.75rem;
  color: var(--teal-bright);
  display: flex;
  align-items: center;
  gap: 0.35rem;
  margin-top: 0.2rem;
}

.status-dot {
  width: 8px;
  height: 8px;
  background-color: var(--success-color);
  border-radius: 50%;
  display: inline-block;
}

.msn-pane-header {
  padding: 0.85rem 1.25rem;
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--text-muted);
  letter-spacing: 1px;
  border-bottom: 1px solid var(--border-color);
  background-color: #0b0e14;
}

.msn-contact-list {
  list-style: none;
  overflow-y: auto;
  flex: 1;
}

.msn-contact-item {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #161d2a;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: background 0.2s ease;
}

.msn-contact-item:hover, .msn-contact-item.active {
  background-color: #18202e;
}

.msn-contact-item.active {
  border-left: 3px solid var(--gold-primary);
}

.msn-chat-pane {
  display: flex;
  flex-direction: column;
  background-color: var(--bg-obsidian);
}

.msn-chat-header {
  padding: 1rem 1.5rem;
  border-bottom: 1px solid var(--border-color);
  background-color: #0e121a;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.msn-chat-header .active-title {
  font-weight: 700;
  color: var(--text-main);
  font-size: 1rem;
}

.msn-chat-messages {
  flex: 1;
  padding: 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.msn-bubble {
  max-width: 70%;
  padding: 0.85rem 1.1rem;
  border-radius: 6px;
  font-size: 0.95rem;
  line-height: 1.4;
  position: relative;
}

.msn-bubble.incoming {
  background-color: var(--bubble-incoming);
  color: var(--text-main);
  align-self: flex-start;
  border: 1px solid var(--border-color);
}

.msn-bubble.outgoing {
  background-color: var(--bubble-outgoing);
  color: #0b0e14;
  font-weight: 600;
  align-self: flex-end;
}

.msn-meta {
  font-size: 0.65rem;
  opacity: 0.7;
  display: block;
  margin-top: 0.35rem;
  text-align: right;
}

.msn-input-bar {
  padding: 1rem 1.25rem;
  border-top: 1px solid var(--border-color);
  display: flex;
  gap: 0.75rem;
  background-color: #0e121a;
}

.msn-input-bar input {
  flex: 1;
  padding: 0.85rem 1rem;
  background-color: #121620;
  border: 1px solid var(--border-color);
  border-radius: 4px;
  color: var(--text-main);
  outline: none;
}

.msn-input-bar input:focus {
  border-color: var(--teal-bright);
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-main);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 0.5rem;
}

.form-group input {
  width: 100%;
  padding: 0.9rem 1rem;
  background-color: #121620;
  border: 1px solid var(--border-color);
  border-radius: 4px;
  color: var(--text-main);
  font-size: 1rem;
  outline: none;
}

.btn-primary {
  width: 100%;
  padding: 0.9rem 1.25rem;
  background-color: var(--gold-primary);
  color: var(--bg-obsidian);
  border: none;
  border-radius: 4px;
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  text-align: center;
  display: block;
  text-decoration: none;
}

.btn-primary:hover {
  background-color: var(--gold-hover);
}

.btn-secondary {
  background-color: transparent;
  border: 1px solid var(--teal-accent);
  color: var(--teal-bright);
}

.btn-secondary:hover {
  background-color: rgba(0, 128, 128, 0.15);
}

.alert {
  padding: 0.85rem 1rem;
  border-radius: 4px;
  font-size: 0.85rem;
  margin-bottom: 1.5rem;
  display: none;
}

.alert-error {
  background-color: rgba(239, 68, 68, 0.15);
  border: 1px solid var(--error-color);
  color: var(--error-color);
}

footer {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.5rem;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.8rem;
  border-top: 1px solid var(--border-color);
}

@media (max-width: 768px) {
  .msn-stage {
    grid-template-columns: 1fr;
    height: 80vh;
  }
  .msn-contact-pane.hidden-mobile {
    display: none;
  }
  .msn-chat-pane.hidden-mobile {
    display: none;
  }
}
CSSEOF

echo "==> Constructing Pocket MSN Chat Client Page (chat.html)..."
cat <<'HTMLEOF' > "$APP_DIR/chat.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Pocket MSN Messenger</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="page-layout wide">
    <div class="msn-stage">
      <div class="msn-contact-pane" id="contact-pane">
        <div class="msn-user-card">
          <div class="identity" id="my-identity">Loading...</div>
          <div class="status"><span class="status-dot"></span> Online (Available)</div>
        </div>
        <div class="msn-pane-header">DIRECTORY & CONTACTS</div>
        <ul class="msn-contact-list" id="contact-list"></ul>
      </div>

      <div class="msn-chat-pane hidden-mobile" id="chat-pane">
        <div class="msn-chat-header">
          <button id="back-to-contacts" class="btn-primary btn-secondary" style="width: auto; padding: 0.4rem 0.75rem; font-size: 0.8rem; display: none;">&larr; Contacts</button>
          <div class="active-title" id="chat-with-title">Select a contact to start messaging</div>
          <span style="font-size: 0.75rem; color: var(--teal-bright);" id="chat-status-tag">End-to-End Persisted</span>
        </div>

        <div class="msn-chat-messages" id="message-container">
          <div style="text-align: center; color: var(--text-muted); margin: auto; font-size: 0.9rem;">
            Select any registered user from your directory list to initiate direct messages.
          </div>
        </div>

        <div class="msn-input-bar">
          <input type="text" id="chat-input" placeholder="Type a message..." disabled>
          <button id="send-btn" class="btn-primary" style="width: auto; padding: 0.85rem 1.5rem;" disabled>Send</button>
        </div>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Pocket MSN");

    const session = AuthStore.getSession();
    if (!session) {
      window.location.href = 'login.html';
    }

    document.getElementById('my-identity').textContent = session.identity;

    let activeTarget = null;
    let pollTimer = null;

    function loadContacts() {
      const users = AuthStore.getUsers().filter(u => u.identity.toLowerCase() !== session.identity.toLowerCase());
      const listEl = document.getElementById('contact-list');
      listEl.innerHTML = '';

      if (users.length === 0) {
        listEl.innerHTML = `<li style="padding: 1.25rem; font-size: 0.85rem; color: var(--text-muted); text-align: center;">No other registered users. Open another tab/browser to register a 2nd user!</li>`;
        return;
      }

      users.forEach(user => {
        const li = document.createElement('li');
        li.className = `msn-contact-item ${activeTarget === user.identity ? 'active' : ''}`;
        li.innerHTML = `
          <div>
            <div style="font-weight: 600; font-size: 0.9rem;">${escapeHTML(user.identity)}</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">${user.type === 'phone' ? '📱 Mobile' : '✉️ Email'}</div>
          </div>
          <span class="status-dot"></span>
        `;
        li.addEventListener('click', () => selectContact(user.identity));
        listEl.appendChild(li);
      });
    }

    function selectContact(targetIdentity) {
      activeTarget = targetIdentity;
      document.getElementById('chat-with-title').textContent = `@${activeTarget}`;
      document.getElementById('chat-input').disabled = false;
      document.getElementById('send-btn').disabled = false;

      // Mobile responsive toggle
      if (window.innerWidth <= 768) {
        document.getElementById('contact-pane').classList.add('hidden-mobile');
        document.getElementById('chat-pane').classList.remove('hidden-mobile');
        document.getElementById('back-to-contacts').style.display = 'block';
      }

      loadContacts();
      renderMessages();

      if (pollTimer) clearInterval(pollTimer);
      pollTimer = setInterval(renderMessages, 1000);
    }

    function renderMessages() {
      if (!activeTarget) return;
      const msgs = AuthStore.getMessages(session.identity, activeTarget);
      const container = document.getElementById('message-container');

      const isScrolledBottom = container.scrollHeight - container.scrollTop <= container.clientHeight + 50;

      container.innerHTML = msgs.length === 0 ? 
        `<div style="text-align: center; color: var(--text-muted); margin: auto; font-size: 0.85rem;">No conversation history yet. Send a message to start chatting with ${escapeHTML(activeTarget)}.</div>` : '';

      msgs.forEach(m => {
        const isMe = m.sender === session.identity;
        const bubble = document.createElement('div');
        bubble.className = `msn-bubble ${isMe ? 'outgoing' : 'incoming'}`;
        bubble.innerHTML = `
          ${escapeHTML(m.text)}
          <span class="msn-meta">${m.timestamp}</span>
        `;
        container.appendChild(bubble);
      });

      if (isScrolledBottom) {
        container.scrollTop = container.scrollHeight;
      }
    }

    function dispatchMessage() {
      const input = document.getElementById('chat-input');
      const text = input.value.trim();
      if (!text || !activeTarget) return;

      AuthStore.sendMessage(session.identity, activeTarget, text);
      input.value = '';
      renderMessages();
    }

    document.getElementById('send-btn').addEventListener('click', dispatchMessage);
    document.getElementById('chat-input').addEventListener('keypress', (e) => {
      if (e.key === 'Enter') dispatchMessage();
    });

    document.getElementById('back-to-contacts').addEventListener('click', () => {
      document.getElementById('contact-pane').classList.remove('hidden-mobile');
      document.getElementById('chat-pane').classList.add('hidden-mobile');
      document.getElementById('back-to-contacts').style.display = 'none';
    });

    function escapeHTML(str) {
      return str.replace(/[&<>'"]/g, 
        tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag] || tag)
      );
    }

    loadContacts();
  </script>
</body>
</html>
HTMLEOF

echo "==> Updating Navigation Links..."
cat <<'JSEOF' > "$APP_DIR/assets/js/app.js"
document.addEventListener('DOMContentLoaded', () => {
  AuthApp.init();
});

const AuthApp = {
  init: () => {
    AuthApp.updateNav();
  },

  updateNav: () => {
    const session = AuthStore.getSession();
    const nav = document.getElementById('main-nav');
    if (!nav) return;

    if (session) {
      nav.innerHTML = `
        <a href="chat.html">Pocket MSN</a>
        <a href="dashboard.html">Dashboard</a>
        <a href="profile.html">Profile</a>
        <a href="#" id="logout-link">Logout (${session.identity})</a>
      `;
      document.getElementById('logout-link')?.addEventListener('click', (e) => {
        e.preventDefault();
        AuthStore.clearSession();
        window.location.href = 'index.html';
      });
    } else {
      nav.innerHTML = `
        <a href="login.html">Login</a>
        <a href="register-email.html">Email Sign Up</a>
        <a href="register-phone.html">Phone Sign Up</a>
      `;
    }
  },

  showAlert: (msg, type = 'error') => {
    const box = document.getElementById('alert-box');
    if (!box) return;
    box.className = `alert alert-${type}`;
    box.textContent = msg;
    box.style.display = 'block';
  }
};
JSEOF

echo "==> Executing Updated MSN Architecture..."
python3 "$APP_DIR/server.py"
