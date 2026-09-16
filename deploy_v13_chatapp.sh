#!/usr/bin/env bash
set -euo pipefail

APP_DIR="auth_system"
mkdir -p "$APP_DIR/assets/css"
mkdir -p "$APP_DIR/assets/js"

echo "==> Terminating existing background processes..."
pkill -f "python3.*server.py" || true
pkill -f "python3 -m http.server" || true
fuser -k 8080/tcp || true

echo "==> Generating Updated CSS (Word Wrapping + Ghost Chat Styling)..."
cat <<'CSSEOF' > "$APP_DIR/assets/css/style.css"
:root {
  --bg-obsidian: #0b0e14;
  --panel-bg: #141821;
  --gold-primary: #d4af37;
  --gold-hover: #f1c40f;
  --teal-accent: #008080;
  --teal-bright: #20b2aa;
  --text-main: #e2e8f0;
  --text-muted: #94a3b8;
  --border-color: #2a3241;
  --error-color: #ef4444;
  --success-color: #10b981;
}

*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, Roboto, sans-serif;
  word-wrap: break-word;
  overflow-wrap: anywhere;
  hyphens: auto;
}

body {
  background-color: var(--bg-obsidian);
  color: var(--text-main);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
}

header {
  width: 100%;
  max-width: 1200px;
  padding: 1.5rem 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-color);
}

header.no-nav nav {
  display: none !important;
}

.brand {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--gold-primary);
  letter-spacing: 1px;
  text-decoration: none;
}

nav a {
  color: var(--text-muted);
  text-decoration: none;
  margin-left: 1.5rem;
  transition: color 0.2s ease;
}

nav a:hover, nav a.active {
  color: var(--teal-bright);
}

main.container {
  width: 100%;
  max-width: 520px;
  margin: auto;
  padding: 2rem 1rem;
}

main.container.wide {
  max-width: 900px;
}

.auth-card {
  background-color: var(--panel-bg);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 2.5rem 2rem;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.5);
}

.auth-card h1 {
  font-size: 1.75rem;
  color: var(--gold-primary);
  margin-bottom: 0.5rem;
  text-align: center;
}

.auth-card p.subtitle {
  color: var(--text-muted);
  font-size: 0.9rem;
  margin-bottom: 1.5rem;
  text-align: center;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.85rem;
  color: var(--text-main);
  margin-bottom: 0.5rem;
}

.form-group input, .form-group select {
  width: 100%;
  padding: 0.85rem 1rem;
  background-color: var(--bg-obsidian);
  border: 1px solid var(--border-color);
  border-radius: 4px;
  color: var(--text-main);
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s ease;
}

.form-group input:focus, .form-group select:focus {
  border-color: var(--teal-bright);
}

.btn-primary {
  width: 100%;
  padding: 0.85rem;
  background-color: var(--gold-primary);
  color: var(--bg-obsidian);
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.2s ease;
  margin-top: 0.5rem;
  text-align: center;
  display: inline-block;
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
  padding: 0.75rem 1rem;
  border-radius: 4px;
  font-size: 0.85rem;
  margin-bottom: 1rem;
  display: none;
}

.alert-error {
  background-color: rgba(239, 68, 68, 0.15);
  border: 1px solid var(--error-color);
  color: var(--error-color);
}

.alert-success {
  background-color: rgba(16, 185, 129, 0.15);
  border: 1px solid var(--success-color);
  color: var(--success-color);
}

/* --- Ghost Chat Styles --- */
.ghost-chat-container {
  display: grid;
  grid-template-columns: 240px 1fr;
  height: 520px;
  background-color: var(--bg-obsidian);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  overflow: hidden;
}

.ghost-sidebar {
  border-right: 1px solid var(--border-color);
  background-color: #0d1117;
  display: flex;
  flex-direction: column;
}

.ghost-sidebar-header {
  padding: 1rem;
  border-bottom: 1px solid var(--border-color);
  font-weight: 700;
  color: var(--gold-primary);
  font-size: 0.9rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ghost-thread-list {
  list-style: none;
  overflow-y: auto;
}

.ghost-thread-item {
  padding: 0.85rem 1rem;
  border-bottom: 1px solid #1a202c;
  cursor: pointer;
  transition: background 0.2s ease;
}

.ghost-thread-item.active {
  background-color: #161c26;
  border-left: 3px solid var(--gold-primary);
}

.ghost-window {
  display: flex;
  flex-direction: column;
  background-color: var(--bg-obsidian);
}

.ghost-messages-area {
  flex: 1;
  padding: 1.25rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.ghost-bubble {
  max-width: 80%;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  font-size: 0.9rem;
  position: relative;
  transition: opacity 0.5s ease;
}

.ghost-bubble.incoming {
  background-color: #1e2430;
  color: var(--text-main);
  align-self: flex-start;
  border: 1px solid var(--border-color);
}

.ghost-bubble.outgoing {
  background-color: var(--gold-primary);
  color: var(--bg-obsidian);
  font-weight: 600;
  align-self: flex-end;
}

.ghost-bubble.ghost-fading {
  animation: ghostFade 5s forwards;
}

@keyframes ghostFade {
  0% { opacity: 1; filter: blur(0px); }
  70% { opacity: 0.3; filter: blur(1px); }
  100% { opacity: 0; filter: blur(4px); display: none; }
}

.ghost-input-bar {
  padding: 0.85rem;
  border-top: 1px solid var(--border-color);
  display: flex;
  gap: 0.5rem;
  background-color: #0d1117;
}

.ghost-timer-tag {
  font-size: 0.7rem;
  opacity: 0.7;
  display: block;
  margin-top: 0.25rem;
}

footer {
  width: 100%;
  max-width: 1200px;
  padding: 1.5rem 1rem;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.8rem;
  border-top: 1px solid var(--border-color);
}

@media (max-width: 680px) {
  .ghost-chat-container {
    grid-template-columns: 1fr;
    height: 600px;
  }
  .ghost-sidebar {
    height: 140px;
  }
}
CSSEOF

echo "==> Creating Capture Page (index.html) with NO Header Navigation..."
cat <<'HTMLEOF' > "$APP_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Welcome | Executive Auth & Ghost Chat</title>
</head>
<body>
  <header id="site-header" class="no-nav">
    <a href="index.html" class="brand">EXECUTIVE CHAT</a>
  </header>

  <main class="container">
    <div class="auth-card" style="text-align: center;">
      <h1>EXECUTIVE CHAT</h1>
      <p class="subtitle">Zero-dependency encrypted messaging with self-destructing Ghost Chat mode.</p>
      
      <div style="display: flex; flex-direction: column; gap: 0.85rem; margin-top: 2rem;">
        <a href="register-email.html" class="btn-primary">Get Started (Email)</a>
        <a href="register-phone.html" class="btn-primary btn-secondary">Get Started (Mobile SMS)</a>
        <a href="login.html" style="color: var(--teal-bright); text-decoration: none; margin-top: 1rem; font-size: 0.9rem;">Already registered? Sign In</a>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Welcome", true);
  </script>
</body>
</html>
HTMLEOF

echo "==> Updating Layout Script (supports hiding nav on capture page)..."
cat <<'JSEOF' > "$APP_DIR/assets/js/layout.js"
function renderLayout(titleText, hideNav = false) {
  const header = document.getElementById('site-header');
  if (hideNav) {
    header.classList.add('no-nav');
    header.innerHTML = `<a href="index.html" class="brand">EXECUTIVE CHAT</a>`;
  } else {
    header.classList.remove('no-nav');
    header.innerHTML = `
      <a href="index.html" class="brand">EXECUTIVE CHAT</a>
      <nav id="main-nav"></nav>
    `;
  }

  document.getElementById('site-footer').innerHTML = `
    &copy; ${new Date().getFullYear()} Executive Auth & Ghost Chat Platform. Standalone Architecture.
  `;

  if (titleText) {
    document.title = `${titleText} | Executive Chat`;
  }
}
JSEOF

echo "==> Generating Ghost Chat Messenger Page (chat.html)..."
cat <<'HTMLEOF' > "$APP_DIR/chat.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Ghost Chat Interface</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="container wide">
    <div class="auth-card">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
        <h1 style="text-align: left; margin: 0;">Ghost Chat</h1>
        <span style="font-size: 0.8rem; color: var(--teal-bright); border: 1px solid var(--teal-accent); padding: 0.25rem 0.6rem; border-radius: 4px;">
          👻 Ghost Mode Active (Auto-Destruct)
        </span>
      </div>

      <div class="ghost-chat-container">
        <div class="ghost-sidebar">
          <div class="ghost-sidebar-header">
            <span>CHANNELS</span>
            <span style="font-size: 0.7rem; color: var(--gold-primary);">SECURE</span>
          </div>
          <ul class="ghost-thread-list">
            <li class="ghost-thread-item active">
              <div style="font-weight: 600;"># General Ghost Thread</div>
              <div style="font-size: 0.75rem; color: var(--text-muted);">Self-destruct timer: 10s</div>
            </li>
          </ul>
        </div>

        <div class="ghost-window">
          <div class="ghost-messages-area" id="ghost-msg-box">
            <div class="ghost-bubble incoming">
              Welcome to Ghost Chat. Messages automatically fade and self-destruct after dispatch.
              <span class="ghost-timer-tag">System Notification</span>
            </div>
          </div>

          <div class="ghost-input-bar">
            <input type="text" id="ghost-input" class="form-control" placeholder="Type a self-destructing ghost message..." style="margin: 0;">
            <button id="ghost-send-btn" class="btn-primary" style="width: auto; margin: 0; padding: 0.85rem 1.25rem;">Send</button>
          </div>
        </div>
      </div>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Ghost Chat");

    const session = AuthStore.getSession();
    if (!session) {
      window.location.href = 'login.html';
    }

    const msgBox = document.getElementById('ghost-msg-box');
    const inputField = document.getElementById('ghost-input');
    const sendBtn = document.getElementById('ghost-send-btn');

    function sendGhostMessage() {
      const text = inputField.value.trim();
      if (!text) return;

      const bubble = document.createElement('div');
      bubble.className = 'ghost-bubble outgoing';
      bubble.innerHTML = `${escapeHTML(text)} <span class="ghost-timer-tag">Self-destructing in 10s...</span>`;

      msgBox.appendChild(bubble);
      inputField.value = '';
      msgBox.scrollTop = msgBox.scrollHeight;

      // Ghost Chat Self-Destruct Mechanics (10-second timer)
      setTimeout(() => {
        bubble.classList.add('ghost-fading');
        setTimeout(() => {
          bubble.remove();
        }, 5000);
      }, 5000);
    }

    function escapeHTML(str) {
      return str.replace(/[&<>'"]/g, 
        tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag] || tag)
      );
    }

    sendBtn.addEventListener('click', sendGhostMessage);
    inputField.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendGhostMessage();
    });
  </script>
</body>
</html>
HTMLEOF

echo "==> Updating Navigation Links in App JS..."
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
        <a href="dashboard.html">Dashboard</a>
        <a href="chat.html">Ghost Chat</a>
        <a href="profile.html">Profile</a>
        <a href="settings.html">Settings</a>
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

echo "==> Launching Server..."
python3 "$APP_DIR/server.py"
