#!/usr/bin/env bash
set -euo pipefail

APP_DIR="auth_system"
mkdir -p "$APP_DIR/assets/css"
mkdir -p "$APP_DIR/assets/js"

echo "==> Terminating stale background processes..."
pkill -f "python3.*server.py" || true
pkill -f "python3 -m http.server" || true
fuser -k 8080/tcp || true

echo "==> Writing Seamless Executive CSS..."
cat <<'CSSEOF' > "$APP_DIR/assets/css/style.css"
:root {
  --bg-obsidian: #0b0e14;
  --gold-primary: #d4af37;
  --gold-hover: #f1c40f;
  --teal-accent: #008080;
  --teal-bright: #20b2aa;
  --text-main: #e2e8f0;
  --text-muted: #8b98a5;
  --border-color: #1e2638;
  --error-color: #ef4444;
  --success-color: #10b981;
}

*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, monospace;
  word-wrap: break-word;
  overflow-wrap: anywhere;
  hyphens: auto;
}

html, body {
  background-color: var(--bg-obsidian);
  color: var(--text-main);
  min-height: 100vh;
}

body {
  display: flex;
  flex-direction: column;
}

/* --- Top Bar --- */
header {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.5rem;
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
  gap: 1.5rem;
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

/* --- Direct Page Layouts --- */
main.page-layout {
  flex: 1;
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
  padding: 3rem 1.5rem;
  display: flex;
  flex-direction: column;
}

main.page-layout.wide {
  max-width: 1200px;
  padding: 2rem 1.5rem;
}

.page-title {
  font-size: 1.75rem;
  color: var(--gold-primary);
  margin-bottom: 0.5rem;
  letter-spacing: 0.5px;
}

.page-subtitle {
  color: var(--text-muted);
  font-size: 0.95rem;
  margin-bottom: 2rem;
  line-height: 1.5;
}

/* --- Form System --- */
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

.form-group input, .form-group select {
  width: 100%;
  padding: 0.9rem 1rem;
  background-color: #121620;
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

/* --- Action Elements --- */
.btn-primary {
  width: 100%;
  padding: 1rem;
  background-color: var(--gold-primary);
  color: var(--bg-obsidian);
  border: none;
  border-radius: 4px;
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 0.2s ease;
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
  border-color: var(--teal-bright);
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

.alert-success {
  background-color: rgba(16, 185, 129, 0.15);
  border: 1px solid var(--success-color);
  color: var(--success-color);
}

/* --- Direct Full-Width Ghost Chat --- */
.ghost-workspace {
  display: grid;
  grid-template-columns: 280px 1fr;
  min-height: 65vh;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  overflow: hidden;
}

.ghost-sidebar {
  border-right: 1px solid var(--border-color);
  background-color: #0d1118;
  display: flex;
  flex-direction: column;
}

.ghost-sidebar-header {
  padding: 1.25rem 1rem;
  border-bottom: 1px solid var(--border-color);
  font-weight: 700;
  color: var(--gold-primary);
  font-size: 0.8rem;
  letter-spacing: 1px;
}

.ghost-thread-list {
  list-style: none;
}

.ghost-thread-item {
  padding: 1.1rem 1rem;
  border-bottom: 1px solid #161d2a;
  cursor: pointer;
}

.ghost-thread-item.active {
  background-color: #141b26;
  border-left: 3px solid var(--gold-primary);
}

.ghost-stage {
  display: flex;
  flex-direction: column;
  background-color: var(--bg-obsidian);
}

.ghost-messages-area {
  flex: 1;
  padding: 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.ghost-bubble {
  max-width: 70%;
  padding: 0.9rem 1.1rem;
  border-radius: 6px;
  font-size: 0.95rem;
  line-height: 1.4;
}

.ghost-bubble.incoming {
  background-color: #141a24;
  color: var(--text-main);
  align-self: flex-start;
  border: 1px solid var(--border-color);
}

.ghost-bubble.outgoing {
  background-color: var(--gold-primary);
  color: #0b0e14;
  font-weight: 600;
  align-self: flex-end;
}

.ghost-bubble.ghost-fading {
  animation: ghostFade 5s forwards;
}

@keyframes ghostFade {
  0% { opacity: 1; filter: blur(0px); }
  70% { opacity: 0.2; filter: blur(2px); }
  100% { opacity: 0; filter: blur(6px); visibility: hidden; }
}

.ghost-input-bar {
  padding: 1.25rem;
  border-top: 1px solid var(--border-color);
  display: flex;
  gap: 0.85rem;
  background-color: #0d1118;
}

.ghost-timer-tag {
  font-size: 0.7rem;
  opacity: 0.75;
  display: block;
  margin-top: 0.35rem;
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
  main.page-layout {
    padding: 2rem 1rem;
  }
  .ghost-workspace {
    grid-template-columns: 1fr;
  }
  .ghost-sidebar {
    display: none;
  }
  .ghost-bubble {
    max-width: 85%;
  }
}
CSSEOF

echo "==> Updating Capture Page (index.html)..."
cat <<'HTMLEOF' > "$APP_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Executive Chat Platform</title>
</head>
<body>
  <header id="site-header" class="no-nav">
    <a href="index.html" class="brand">EXECUTIVE CHAT</a>
  </header>

  <main class="page-layout">
    <h1 class="page-title" style="text-align: center;">EXECUTIVE CHAT</h1>
    <p class="page-subtitle" style="text-align: center;">Zero-dependency identity system & self-destructing ghost chat.</p>
    
    <div style="display: flex; flex-direction: column; gap: 1rem; margin-top: 1rem;">
      <a href="register-email.html" class="btn-primary">Register via Email</a>
      <a href="register-phone.html" class="btn-primary btn-secondary">Register via Phone (SMS)</a>
      <a href="login.html" style="color: var(--teal-bright); text-decoration: none; text-align: center; margin-top: 1rem; font-size: 0.9rem;">Sign In to Existing Identity</a>
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

echo "==> Updating Ghost Chat Page (chat.html)..."
cat <<'HTMLEOF' > "$APP_DIR/chat.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Ghost Chat</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="page-layout wide">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
      <div>
        <h1 class="page-title" style="margin: 0;">Ghost Chat</h1>
        <p style="color: var(--text-muted); font-size: 0.85rem; margin-top: 0.25rem;">Ephemeral messaging thread with automated self-destruct cycle.</p>
      </div>
      <span style="font-size: 0.8rem; color: var(--teal-bright); border: 1px solid var(--teal-accent); padding: 0.35rem 0.75rem; border-radius: 4px;">
        👻 Ghost Mode Active
      </span>
    </div>

    <div class="ghost-workspace">
      <div class="ghost-sidebar">
        <div class="ghost-sidebar-header">CHANNELS</div>
        <ul class="ghost-thread-list">
          <li class="ghost-thread-item active">
            <div style="font-weight: 600;"># Primary Channel</div>
            <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 0.25rem;">Auto-Destruct: 10 Seconds</div>
          </li>
        </ul>
      </div>

      <div class="ghost-stage">
        <div class="ghost-messages-area" id="ghost-msg-box">
          <div class="ghost-bubble incoming">
            Welcome to Ghost Chat. Messages automatically fade and destruct after transmission.
            <span class="ghost-timer-tag">System Notification</span>
          </div>
        </div>

        <div class="ghost-input-bar">
          <input type="text" id="ghost-input" placeholder="Type a message..." style="margin: 0;">
          <button id="ghost-send-btn" class="btn-primary" style="width: auto; padding: 0.9rem 1.75rem;">Send</button>
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

      setTimeout(() => {
        bubble.classList.add('ghost-fading');
        setTimeout(() => bubble.remove(), 5000);
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

echo "==> Re-launching Server..."
python3 "$APP_DIR/server.py"
