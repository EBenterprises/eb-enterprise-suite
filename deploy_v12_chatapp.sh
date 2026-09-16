#!/usr/bin/env bash
set -e

echo "==> Terminating background Python HTTP servers..."
pkill -f "python3 -m http.server" || true

echo "==> Generating Executive Spectrum CSS (style.css)..."
cat <<'CSSEOF' > style.css
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  overflow-x: hidden;
  scroll-behavior: smooth;
  font-size: 100%;
}

body {
  min-height: 100vh;
  min-height: 100dvh;
  width: 100%;
  background-color: #0d0e12;
  color: #e0e6ed;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}

.app-shell {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  min-height: 100dvh;
}

.site-header {
  position: sticky;
  top: 0;
  z-index: 1000;
  background-color: rgba(13, 14, 18, 0.92);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid #1e232d;
}

.header-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 4.25rem;
}

.brand-title {
  font-weight: 700;
  font-size: 1.25rem;
  color: #d4af37;
  text-decoration: none;
  letter-spacing: 0.05em;
}

.brand-badge {
  color: #008080;
  font-size: 0.85rem;
  font-weight: 600;
}

.main-content {
  flex: 1 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
}

.page-view {
  display: none;
  width: 100%;
  max-width: 540px;
}

.page-view.active {
  display: block;
}

.page-view.wide {
  max-width: 1000px;
}

.card {
  background: #141820;
  border: 1px solid #222834;
  border-radius: 14px;
  padding: 2.25rem;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.5);
}

.card-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #f0f4f8;
  margin-bottom: 0.5rem;
}

.card-subtitle {
  color: #8a99ad;
  font-size: 0.95rem;
  margin-bottom: 1.75rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: #c5d0de;
}

.form-control {
  width: 100%;
  min-height: 50px;
  padding: 0.75rem 1rem;
  background-color: #0d0e12;
  border: 1px solid #222834;
  border-radius: 8px;
  color: #e0e6ed;
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.form-control:focus {
  border-color: #008080;
  box-shadow: 0 0 0 3px rgba(0, 128, 128, 0.18);
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 50px;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
  text-decoration: none;
  border: 1px solid transparent;
  transition: all 0.2s ease;
  margin-top: 0.5rem;
}

.btn-primary {
  background-color: #d4af37;
  color: #0d0e12;
}

.btn-primary:hover {
  background-color: #f1c40f;
}

.btn-secondary {
  background-color: transparent;
  border-color: #008080;
  color: #008080;
}

.btn-secondary:hover {
  background-color: rgba(0, 128, 128, 0.12);
  color: #00b3b3;
}

.btn-partner {
  background-color: #1e232d;
  border-color: #2a313d;
  color: #f0f4f8;
  display: flex;
  gap: 0.75rem;
}

.btn-partner:hover {
  background-color: #262c38;
}

.divider {
  display: flex;
  align-items: center;
  text-align: center;
  margin: 1.5rem 0;
  color: #8a99ad;
  font-size: 0.85rem;
}

.divider::before, .divider::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid #222834;
}

.divider span {
  padding: 0 0.75rem;
}

.text-link {
  color: #008080;
  text-decoration: none;
  font-weight: 600;
  cursor: pointer;
}

.text-link:hover {
  color: #00b3b3;
  text-decoration: underline;
}

/* Chat Layout Mechanics */
.chat-container {
  display: grid;
  grid-template-columns: 280px 1fr;
  height: 600px;
  background: #141820;
  border: 1px solid #222834;
  border-radius: 14px;
  overflow: hidden;
}

.chat-sidebar {
  border-right: 1px solid #222834;
  background: #0d0e12;
  display: flex;
  flex-direction: column;
}

.chat-thread-list {
  list-style: none;
  overflow-y: auto;
}

.chat-thread-item {
  padding: 1rem;
  border-bottom: 1px solid #1a202c;
  cursor: pointer;
}

.chat-thread-item.active {
  background: #18202c;
  border-left: 3px solid #d4af37;
}

.chat-window {
  display: flex;
  flex-direction: column;
}

.chat-messages {
  flex: 1;
  padding: 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message-bubble {
  max-width: 70%;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  font-size: 0.95rem;
}

.message-bubble.incoming {
  background: #1e232d;
  color: #e0e6ed;
  align-self: flex-start;
}

.message-bubble.outgoing {
  background: #d4af37;
  color: #0d0e12;
  font-weight: 500;
  align-self: flex-end;
}

.chat-input-bar {
  padding: 1rem;
  border-top: 1px solid #222834;
  display: flex;
  gap: 0.75rem;
}

.nav-dots {
  display: flex;
  justify-content: center;
  gap: 0.5rem;
  margin-top: 1.5rem;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #222834;
}

.dot.active {
  background: #d4af37;
}

.site-footer {
  border-top: 1px solid #1e232d;
  background-color: #090a0d;
  padding: 1.5rem 0;
  text-align: center;
  color: #8a99ad;
  font-size: 0.85rem;
}
CSSEOF

echo "==> Generating HTML & JS Router (index.html)..."
cat <<'HTMLEOF' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>EB Enterprises | V12 Chat Engine Architecture</title>
  <link rel="stylesheet" href="style.css">
</head>
<body class="app-shell">

  <header class="site-header">
    <div class="header-container">
      <a href="#" class="brand-title" onclick="navigateTo(1)">EB ENTERPRISES</a>
      <span class="brand-badge" id="step-indicator">Page 1 / 12</span>
    </div>
  </header>

  <main class="main-content">

    <!-- PAGE 1: Get Started Capture -->
    <section id="page-1" class="page-view active">
      <div class="card" style="text-align: center;">
        <h1 class="card-title" style="color: #d4af37; font-size: 2.25rem;">EB ARCHITECTURE V12</h1>
        <p class="card-subtitle">Zero-dependency, high-throughput encrypted messaging protocol.</p>
        <button class="btn btn-primary" onclick="navigateTo(2)">Get Started</button>
      </div>
    </section>

    <!-- PAGE 2: Login or Signup Selection -->
    <section id="page-2" class="page-view">
      <div class="card">
        <h2 class="card-title">Welcome</h2>
        <p class="card-subtitle">Select an action to enter the mesh network.</p>
        <button class="btn btn-primary" onclick="navigateTo(3)">Create New Account</button>
        <button class="btn btn-secondary" onclick="navigateTo(7)">Sign In Existing Account</button>
        
        <div class="divider"><span>OR CONTINUE WITH</span></div>
        <button class="btn btn-partner" onclick="partnerAuth()">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#d4af37" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 12l2 2 4-4"/></svg>
          Sign In with Enterprise Partner
        </button>
      </div>
    </section>

    <!-- PAGE 3: Email & Password Capture -->
    <section id="page-3" class="page-view">
      <div class="card">
        <h2 class="card-title">Credentials</h2>
        <p class="card-subtitle">Step 1 of registration sequence.</p>
        <form onsubmit="event.preventDefault(); navigateTo('3b');">
          <div class="form-group">
            <label>Email Address</label>
            <input type="email" class="form-control" placeholder="operator@domain.com" required>
          </div>
          <div class="form-group">
            <label>Master Password</label>
            <input type="password" class="form-control" placeholder="••••••••••••" required>
          </div>
          <button type="submit" class="btn btn-primary">Continue to Demographics</button>
        </form>
      </div>
    </section>

    <!-- PAGE 3b: Birthday & Gender Capture -->
    <section id="page-3b" class="page-view">
      <div class="card">
        <h2 class="card-title">Demographics</h2>
        <p class="card-subtitle">Provide verified profile criteria.</p>
        <form onsubmit="event.preventDefault(); navigateTo(4);">
          <div class="form-group">
            <label>Date of Birth</label>
            <input type="date" class="form-control" required>
          </div>
          <div class="form-group">
            <label>Gender Identification</label>
            <select class="form-control" required>
              <option value="">Select gender option...</option>
              <option value="male">Male</option>
              <option value="female">Female</option>
              <option value="nonbinary">Non-Binary</option>
              <option value="undisclosed">Prefer not to say</option>
            </select>
          </div>
          <button type="submit" class="btn btn-primary">Proceed to Handle Assignment</button>
        </form>
      </div>
    </section>

    <!-- PAGE 4: Unique Username Assignment -->
    <section id="page-4" class="page-view">
      <div class="card">
        <h2 class="card-title">Handle Assignment</h2>
        <p class="card-subtitle">Assign a unique handle for network routing.</p>
        <form onsubmit="event.preventDefault(); navigateTo(8);">
          <div class="form-group">
            <label>Unique Username</label>
            <input type="text" id="username-input" class="form-control" placeholder="e.g. operator_v12" required>
          </div>
          <button type="button" class="btn btn-secondary" onclick="generateHandle()" style="margin-bottom: 0.75rem;">🎲 Randomize Handle</button>
          <button type="submit" class="btn btn-primary">Confirm & Register</button>
        </form>
      </div>
    </section>

    <!-- PAGE 5: Password Recovery Request -->
    <section id="page-5" class="page-view">
      <div class="card">
        <h2 class="card-title">Account Recovery</h2>
        <p class="card-subtitle">Enter registered credentials to receive reset tokens.</p>
        <form onsubmit="event.preventDefault(); alert('Reset token dispatched.'); navigateTo(7);">
          <div class="form-group">
            <label>Registered Email</label>
            <input type="email" class="form-control" placeholder="operator@domain.com" required>
          </div>
          <button type="submit" class="btn btn-primary">Dispatch Recovery Token</button>
          <div style="text-align: center; margin-top: 1.25rem;">
            <a class="text-link" onclick="navigateTo(7)">← Return to Sign In</a>
          </div>
        </form>
      </div>
    </section>

    <!-- PAGE 6/7: Sign In & Authentication Challenge -->
    <section id="page-7" class="page-view">
      <div class="card">
        <h2 class="card-title">Authentication</h2>
        <p class="card-subtitle">Enter network credentials.</p>
        <form onsubmit="event.preventDefault(); navigateTo(8);">
          <div class="form-group">
            <label>Email or Handle</label>
            <input type="text" class="form-control" required>
          </div>
          <div class="form-group">
            <label>Password</label>
            <input type="password" class="form-control" required>
          </div>
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
            <a class="text-link" onclick="navigateTo(5)" style="font-size: 0.85rem;">Forgot password?</a>
          </div>
          <button type="submit" class="btn btn-primary">Authenticate</button>
        </form>

        <div class="divider"><span>ENTERPRISE SSO</span></div>
        <button class="btn btn-partner" onclick="partnerAuth()">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#d4af37" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></svg>
          Partner SSO Direct Access
        </button>
      </div>
    </section>

    <!-- PAGE 8: MFA Verification (Email / SMS) -->
    <section id="page-8" class="page-view">
      <div class="card">
        <h2 class="card-title">Two-Factor Audit</h2>
        <p class="card-subtitle">SMS/Email verification token sent to endpoint.</p>
        <form onsubmit="event.preventDefault(); navigateTo(11);">
          <div class="form-group">
            <label>6-Digit Verification Token</label>
            <input type="text" class="form-control" placeholder="884920" maxlength="6" style="letter-spacing: 0.5em; text-align: center;" required>
          </div>
          <button type="submit" class="btn btn-primary">Verify & Authorize Session</button>
        </form>
      </div>
    </section>

    <!-- PAGE 9: System Settings -->
    <section id="page-9" class="page-view">
      <div class="card">
        <h2 class="card-title">System Settings</h2>
        <p class="card-subtitle">Configure application runtime parameters.</p>
        <div class="form-group">
          <label>Theme Spectrum</label>
          <input type="text" class="form-control" value="Obsidian Gold / Teal (Executive)" readonly>
        </div>
        <div class="form-group">
          <label>Encrypted Storage</label>
          <input type="text" class="form-control" value="Zero-Dependency LocalVault Enabled" readonly>
        </div>
        <button class="btn btn-primary" onclick="navigateTo(11)">Return to Main Dashboard</button>
      </div>
    </section>

    <!-- PAGE 10: Messenger Interfaces -->
    <section id="page-10" class="page-view wide">
      <div class="chat-container">
        <div class="chat-sidebar">
          <div style="padding: 1rem; border-bottom: 1px solid #222834; font-weight: 700; color: #d4af37;">Active Threads</div>
          <ul class="chat-thread-list">
            <li class="chat-thread-item active">
              <div style="font-weight: 600; color: #f0f4f8;">System Core</div>
              <div style="font-size: 0.8rem; color: #8a99ad;">Encrypted handshake OK</div>
            </li>
            <li class="chat-thread-item">
              <div style="font-weight: 600; color: #f0f4f8;">EB Operator</div>
              <div style="font-size: 0.8rem; color: #8a99ad;">V12 Deployment complete</div>
            </li>
          </ul>
        </div>
        <div class="chat-window">
          <div class="chat-messages" id="chat-messages">
            <div class="message-bubble incoming">V12 Mesh Network operational. Standard socket clear.</div>
            <div class="message-bubble outgoing">Awaiting outbound dispatch commands.</div>
          </div>
          <div class="chat-input-bar">
            <input type="text" id="chat-msg-input" class="form-control" placeholder="Type encrypted message...">
            <button class="btn btn-primary" style="width: auto; margin-top: 0;" onclick="sendMessage()">Send</button>
          </div>
        </div>
      </div>
      <button class="btn btn-secondary" onclick="navigateTo(11)" style="margin-top: 1rem;">Return to Homepage Hub</button>
    </section>

    <!-- PAGE 11: Main Homepage / Dashboard -->
    <section id="page-11" class="page-view">
      <div class="card">
        <h2 class="card-title" style="color: #d4af37;">Platform Homepage Hub</h2>
        <p class="card-subtitle">Core execution control center.</p>
        <div style="display: flex; flex-direction: column; gap: 0.75rem;">
          <button class="btn btn-primary" onclick="navigateTo(10)">💬 Launch Messenger Interface</button>
          <button class="btn btn-secondary" onclick="navigateTo(12)">👤 User Profile Dashboard</button>
          <button class="btn btn-secondary" onclick="navigateTo(9)">⚙️ System Settings</button>
          <button class="btn btn-partner" onclick="navigateTo(2)">🔒 Lock Session & Exit</button>
        </div>
      </div>
    </section>

    <!-- PAGE 12: User Profile Dashboard -->
    <section id="page-12" class="page-view">
      <div class="card">
        <h2 class="card-title">User Profile</h2>
        <p class="card-subtitle">Verified system handle and node status.</p>
        <div class="form-group">
          <label>Active Handle</label>
          <input type="text" class="form-control" value="operator_v12" readonly>
        </div>
        <div class="form-group">
          <label>Node ID</label>
          <input type="text" class="form-control" value="NODE-88392-EB" readonly>
        </div>
        <button class="btn btn-primary" onclick="navigateTo(11)">Return to Homepage</button>
      </div>
    </section>

  </main>

  <footer class="site-footer">
    EB ENTERPRISES &copy; 2026 | Zero-Dependency V12 Architecture
  </footer>

  <script>
    const totalPages = 12;

    function navigateTo(pageId) {
      document.querySelectorAll('.page-view').forEach(view => view.classList.remove('active'));
      
      let targetView = document.getElementById(`page-${pageId}`);
      if (!targetView && pageId === '3b') {
        targetView = document.getElementById('page-3b');
      }

      if (targetView) {
        targetView.classList.add('active');
        document.getElementById('step-indicator').textContent = `View ID: ${pageId}`;
      }
    }

    function generateHandle() {
      const prefixes = ['anon', 'node', 'sys', 'unit', 'cipher', 'vector'];
      const randPrefix = prefixes[Math.floor(Math.random() * prefixes.length)];
      const randNum = Math.floor(100000 + Math.random() * 900000);
      document.getElementById('username-input').value = `${randPrefix}_${randNum}`;
    }

    function partnerAuth() {
      alert('Enterprise Partner SSO Handshake Initiated...\nAuthenticating tokens via OAuth Gateway.');
      navigateTo(8);
    }

    function sendMessage() {
      const input = document.getElementById('chat-msg-input');
      const text = input.value.trim();
      if (!text) return;

      const msgContainer = document.getElementById('chat-messages');
      const bubble = document.createElement('div');
      bubble.className = 'message-bubble outgoing';
      bubble.textContent = text;
      msgContainer.appendChild(bubble);

      input.value = '';
      msgContainer.scrollTop = msgContainer.scrollHeight;
    }
  </script>
</body>
</html>
HTMLEOF

echo "==> Deploying Python Native Server..."
python3 -c "
import http.server
import socketserver

start_port = 8080
max_port = 8095

for port in range(start_port, max_port + 1):
    try:
        class ReusableTCPServer(socketserver.TCPServer):
            allow_reuse_address = True

        handler = http.server.SimpleHTTPRequestHandler
        with ReusableTCPServer(('', port), handler) as httpd:
            print(f'\n======================================================')
            print(f'=> V12 Chat App System Live: http://localhost:{port}')
            print(f'======================================================\n')
            httpd.serve_forever()
            break
    except OSError:
        continue
"
