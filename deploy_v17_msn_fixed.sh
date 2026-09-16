#!/usr/bin/env bash
set -euo pipefail

APP_DIR="auth_system"
mkdir -p "$APP_DIR/assets/css"
mkdir -p "$APP_DIR/assets/js"

echo "==> Updating Data Engine with Safe Schema Migration & Persistent Auth..."
cat <<'JSEOF' > "$APP_DIR/assets/js/store.js"
const AuthStore = {
  USERS_KEY: 'eb_msn_users',
  SESSION_KEY: 'eb_msn_session',
  CONVERSATIONS_KEY: 'eb_msn_conversations',

  // Safe migration: Retrieve without wiping
  getUsers: () => {
    try {
      return JSON.parse(localStorage.getItem(AuthStore.USERS_KEY) || '[]');
    } catch (e) {
      return [];
    }
  },

  saveUsers: (users) => localStorage.setItem(AuthStore.USERS_KEY, JSON.stringify(users)),

  getConversations: () => {
    try {
      return JSON.parse(localStorage.getItem(AuthStore.CONVERSATIONS_KEY) || '{}');
    } catch (e) {
      return {};
    }
  },

  saveConversations: (convs) => localStorage.setItem(AuthStore.CONVERSATIONS_KEY, JSON.stringify(convs)),

  register: (identity, password, type = 'phone') => {
    const users = AuthStore.getUsers();
    const cleanIdentity = identity.trim();
    
    if (users.find(u => u.identity.toLowerCase() === cleanIdentity.toLowerCase())) {
      return { success: false, message: 'Identity already registered.' };
    }
    
    const newUser = { 
      id: 'usr_' + Date.now(), 
      identity: cleanIdentity, 
      password: password, 
      type: type,
      status: 'Online' 
    };
    
    users.push(newUser);
    AuthStore.saveUsers(users);
    
    // Auto-login upon registration
    AuthStore.setSession(newUser);
    return { success: true };
  },

  login: (identity, password) => {
    const users = AuthStore.getUsers();
    const cleanIdentity = identity.trim();
    
    const user = users.find(u => 
      u.identity.toLowerCase() === cleanIdentity.toLowerCase() && 
      u.password === password
    );
    
    if (!user) {
      return { success: false, message: 'Invalid credentials. Check identity or password.' };
    }
    
    AuthStore.setSession(user);
    return { success: true };
  },

  setSession: (user) => {
    localStorage.setItem(AuthStore.SESSION_KEY, JSON.stringify({
      id: user.id,
      identity: user.identity,
      type: user.type
    }));
  },

  getSession: () => {
    try {
      return JSON.parse(localStorage.getItem(AuthStore.SESSION_KEY) || 'null');
    } catch (e) {
      return null;
    }
  },

  clearSession: () => localStorage.removeItem(AuthStore.SESSION_KEY),

  getConvId: (userA, userB) => [userA.toLowerCase(), userB.toLowerCase()].sort().join('::'),

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

echo "==> Ensuring Unified Login Interface..."
cat <<'HTMLEOF' > "$APP_DIR/login.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Login - Pocket MSN</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="page-layout">
    <h2 style="color: var(--gold-primary); margin-bottom: 1.5rem; text-align: center;">SIGN IN</h2>
    
    <div id="alert-box" class="alert alert-error"></div>

    <form id="login-form">
      <div class="form-group">
        <label>Identity (Email or Phone)</label>
        <input type="text" id="identity" placeholder="user@domain.com or +1555000" required>
      </div>
      <div class="form-group">
        <label>Password</label>
        <input type="password" id="password" placeholder="••••••••" required>
      </div>
      <button type="submit" class="btn-primary">Login</button>
    </form>

    <div style="margin-top: 1.5rem; text-align: center; font-size: 0.85rem; color: var(--text-muted);">
      Don't have an account? <a href="register-phone.html" style="color: var(--teal-bright);">Register Here</a>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Login");

    document.getElementById('login-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const identity = document.getElementById('identity').value;
      const password = document.getElementById('password').value;

      const res = AuthStore.login(identity, password);
      if (res.success) {
        window.location.href = 'chat.html';
      } else {
        AuthApp.showAlert(res.message);
      }
    });
  </script>
</body>
</html>
HTMLEOF

echo "==> Ensuring Register Interface..."
cat <<'HTMLEOF' > "$APP_DIR/register-phone.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Register - Pocket MSN</title>
</head>
<body>
  <header id="site-header"></header>

  <main class="page-layout">
    <h2 style="color: var(--gold-primary); margin-bottom: 1.5rem; text-align: center;">CREATE ACCOUNT</h2>
    
    <div id="alert-box" class="alert alert-error"></div>

    <form id="register-form">
      <div class="form-group">
        <label>Identity / Username</label>
        <input type="text" id="identity" placeholder="e.g. Easton, User123, or phone" required>
      </div>
      <div class="form-group">
        <label>Password</label>
        <input type="password" id="password" placeholder="••••••••" required>
      </div>
      <button type="submit" class="btn-primary">Create Account & Chat</button>
    </form>

    <div style="margin-top: 1.5rem; text-align: center; font-size: 0.85rem; color: var(--text-muted);">
      Already have an account? <a href="login.html" style="color: var(--teal-bright);">Login</a>
    </div>
  </main>

  <footer id="site-footer"></footer>

  <script src="assets/js/store.js"></script>
  <script src="assets/js/layout.js"></script>
  <script src="assets/js/app.js"></script>
  <script>
    renderLayout("Register");

    document.getElementById('register-form').addEventListener('submit', (e) => {
      e.preventDefault();
      const identity = document.getElementById('identity').value;
      const password = document.getElementById('password').value;

      const res = AuthStore.register(identity, password, 'phone');
      if (res.success) {
        window.location.href = 'chat.html';
      } else {
        AuthApp.showAlert(res.message);
      }
    });
  </script>
</body>
</html>
HTMLEOF

echo "==> Restarting Python Server cleanly..."
pkill -f "python3.*server.py" || true
pkill -f "python3 -m http.server" || true
python3 "$APP_DIR/server.py" &
echo "==> Hotfix complete. Server re-initialized."
