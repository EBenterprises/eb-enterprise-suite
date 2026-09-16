#!/usr/bin/env bash
set -euo pipefail

APP_DIR="auth_system"
mkdir -p "$APP_DIR/assets/css"
mkdir -p "$APP_DIR/assets/js"

echo "==> Terminating stale background processes..."
pkill -f "python3.*server.py" || true
pkill -f "python3 -m http.server" || true
fuser -k 8080/tcp || true

echo "==> Overhauling Stylesheet (Executive Spectrum Theme & Responsive Architecture)..."
cat <<'CSSEOF' > "$APP_DIR/assets/css/style.css"
:root {
  --bg-obsidian: #0b0e14;
  --panel-bg: #141821;
  --panel-border: #232a3b;
  --gold-primary: #d4af37;
  --gold-hover: #f1c40f;
  --teal-accent: #008080;
  --teal-bright: #20b2aa;
  --text-main: #e2e8f0;
  --text-muted: #8b98a5;
  --error-color: #ef4444;
  --success-color: #10b981;
  --radius: 8px;
  --transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
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

body {
  background-color: var(--bg-obsidian);
  color: var(--text-main);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  line-height: 1.5;
}

/* --- Header / Navigation --- */
header {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.25rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--panel-border);
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
  transition: var(--transition);
}

nav a:hover, nav a.active {
  color: var(--teal-bright);
}

/* --- Layout Container --- */
main.container {
  flex: 1;
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
  padding: 2.5rem 1.25rem;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

main.container.wide {
  max-width: 1050px;
}

/* --- Card Architecture --- */
.auth-card {
  background-color: var(--panel-bg);
  border: 1px solid var(--panel-border);
  border-radius: var(--radius);
  padding: 2.25rem 2rem;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.6);
}

.auth-card h1 {
  font-size: 1.5rem;
  color: var(--gold-primary);
  margin-bottom: 0.5rem;
  text-align: center;
  letter-spacing: 0.5px;
}

.auth-card p.subtitle {
  color: var(--text-muted);
  font-size: 0.875rem;
  margin-bottom: 1.75rem;
  text-align: center;
}

/* --- Form Elements --- */
.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-main);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 0.4rem;
}

.form-group input, .form-group select {
  width: 100%;
  padding: 0.8rem 1rem;
  background-color: var(--bg-obsidian);
  border: 1px solid var(--panel-border);
  border-radius: 4px;
  color: var(--text-main);
  font-size: 0.95rem;
  outline: none;
  transition: var(--transition);
}

.form-group input:focus, .form-group select:focus {
  border-color: var(--teal-bright);
  box-shadow: 0 0 0 2px rgba(32, 178, 170, 0.2);
}

/* --- Button Styling --- */
.btn-primary {
  width: 100%;
  padding: 0.85rem;
  background-color: var(--gold-primary);
  color: var(--bg-obsidian);
  border: none;
  border-radius: 4px;
  font-size: 0.95rem;
  font-weight: 700;
  cursor: pointer;
  transition: var(--transition);
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
  border-color: var(--teal-bright);
}

.alert {
  padding: 0.75rem 1rem;
  border-radius: 4px;
  font-size: 0.85rem;
  margin-bottom: 1.25rem;
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

/* --- Ghost Chat UI System --- */
.ghost-chat-container {
  display: grid;
  grid-template-columns: 260px 1fr;
  height: 560px;
  background-color: var(--bg-obsidian);
  border: 1px solid var(--panel-border);
  border-radius: var(--radius);
  overflow: hidden;
}

.ghost-sidebar {
  border-right: 1px solid var(--panel-border);
  background-color: #0e121a;
  display: flex;
  flex-direction: column;
}

.ghost-sidebar-header {
  padding: 1.1rem 1rem;
  border-bottom: 1px solid var(--panel-border);
  font-weight: 700;
  color: var(--gold-primary);
  font-size: 0.8rem;
  letter-spacing: 1px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ghost-thread-list {
  list-style: none;
  overflow-y: auto;
}

.ghost-thread-item {
  padding: 1rem;
  border-bottom: 1px solid #161c28;
  cursor: pointer;
  transition: var(--transition);
}

.ghost-thread-item.active {
  background-color: #151c27;
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
  gap: 1rem;
}

.ghost-bubble {
  max-width: 75%;
  padding: 0.85rem 1.1rem;
  border-radius: 8px;
  font-size: 0.9rem;
  line-height: 1.4;
  position: relative;
  transition: opacity 0.5s ease, filter 0.5s ease;
}

.ghost-bubble.incoming {
  background-color: #171d29;
  color: var(--text-main);
  align-self: flex-start;
  border: 1px solid var(--panel-border);
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
  padding: 1rem;
  border-top: 1px solid var(--panel-border);
  display: flex;
  gap: 0.75rem;
  background-color: #0e121a;
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
  padding: 1.25rem 1.5rem;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.8rem;
  border-top: 1px solid var(--panel-border);
}

@media (max-width: 720px) {
  header {
    flex-direction: column;
    gap: 0.85rem;
  }

  .ghost-chat-container {
    grid-template-columns: 1fr;
    height: 620px;
  }

  .ghost-sidebar {
    height: 120px;
  }

  .ghost-bubble {
    max-width: 88%;
  }
}
CSSEOF

echo "==> Updating Capture Page (index.html) - Zero Navigation Header..."
cat <<'HTMLEOF' > "$APP_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="assets/css/style.css">
  <title>Executive Auth & Ghost Chat Platform</title>
</head>
<body>
  <header id="site-header" class="no-nav">
    <a href="index.html" class="brand">EXECUTIVE CHAT</a>
  </header>

  <main class="container">
    <div class="auth-card">
      <h1>EXECUTIVE CHAT</h1>
      <p class="subtitle">Zero-dependency, fully automated identity management and ephemeral messaging engine.</p>
      
      <div style="display: flex; flex-direction: column; gap: 0.85rem;">
        <a href="register-email.html" class="btn-primary">Register via Email</a>
        <a href="register-phone.html" class="btn-primary btn-secondary">Register via Phone (SMS)</a>
        <a href="login.html" style="color: var(--teal-bright); text-decoration: none; text-align: center; margin-top: 1rem; font-size: 0.875rem;">Existing Identity? Sign In</a>
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

echo "==> Updating Layout Engine Script..."
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
    &copy; ${new Date().getFullYear()} Executive Auth & Ghost Chat Systems. Obsidian-Gold Engine.
  `;

  if (titleText) {
    document.title = `${titleText} | Executive Chat`;
  }
}
JSEOF

echo "==> Re-launching Server..."
python3 "$APP_DIR/server.py"
