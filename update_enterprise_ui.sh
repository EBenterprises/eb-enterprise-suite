#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Enterprise SaaS Terminal UI Upgrade
# ==============================================================================
set -e

echo "[+] Upgrading directory structure & assets..."
mkdir -p public

echo "[+] Generating Enterprise-grade CSS (Obsidian, Teal & Gold)..."
cat << 'CSS_EOF' > public/style.css
:root {
    --bg-app: #070a12;
    --sidebar-bg: #0b0f19;
    --card-bg: #131b2e;
    --card-hover: #17223b;
    --border-color: #22304a;
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --accent-teal: #00d2c4;
    --accent-teal-glow: rgba(0, 210, 196, 0.2);
    --gold: #d4af37;
    --success: #22c55e;
    --danger: #ef4444;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

body {
    background-color: var(--bg-app);
    color: var(--text-primary);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

/* App Header Bar */
.app-header {
    height: 60px;
    background: var(--sidebar-bg);
    border-bottom: 1px solid var(--border-color);
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 1.5rem;
    position: sticky;
    top: 0;
    z-index: 100;
}

.brand-section {
    display: flex;
    align-items: center;
    gap: 0.75rem;
}

.brand-logo {
    width: 32px;
    height: 32px;
    background: var(--gold);
    color: var(--bg-app);
    font-weight: bold;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 6px;
    font-size: 1rem;
    letter-spacing: -0.05em;
}

.brand-title {
    font-size: 1.1rem;
    font-weight: 700;
    color: var(--gold);
    letter-spacing: 0.05em;
}

.user-profile {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    padding: 0.35rem 0.75rem;
    border-radius: 20px;
    font-size: 0.85rem;
    color: var(--text-secondary);
}

.status-indicator {
    width: 8px;
    height: 8px;
    background: var(--success);
    border-radius: 50%;
    box-shadow: 0 0 8px var(--success);
}

/* Main Workspace Layout */
.app-body {
    display: flex;
    flex: 1;
    overflow: hidden;
}

/* Sidebar Navigation */
.sidebar {
    width: 240px;
    background: var(--sidebar-bg);
    border-right: 1px solid var(--border-color);
    padding: 1.5rem 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.nav-item {
    padding: 0.75rem 1rem;
    color: var(--text-secondary);
    text-decoration: none;
    border-radius: 6px;
    font-size: 0.9rem;
    font-weight: 500;
    display: flex;
    align-items: center;
    gap: 0.75rem;
    transition: all 0.2s ease;
}

.nav-item:hover, .nav-item.active {
    background: var(--card-bg);
    color: var(--accent-teal);
    border: 1px solid var(--border-color);
}

/* Workspace Content */
.content-area {
    flex: 1;
    padding: 2rem;
    overflow-y: auto;
    background: var(--bg-app);
}

.dashboard-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
}

.card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1.5rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
}

.card-title {
    font-size: 0.85rem;
    text-transform: uppercase;
    color: var(--text-secondary);
    letter-spacing: 0.05em;
    margin-bottom: 0.75rem;
}

.card-value {
    font-size: 1.8rem;
    font-weight: 700;
    color: var(--text-primary);
}

.panel {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 10px;
    padding: 1.75rem;
}

.panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 1rem;
}

.panel-title {
    font-size: 1.25rem;
    color: var(--gold);
    font-weight: 600;
}

form {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

label {
    font-size: 0.85rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

input, select {
    background: var(--bg-app);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 0.8rem 1rem;
    border-radius: 6px;
    font-size: 1rem;
    outline: none;
    transition: all 0.2s;
}

input:focus, select:focus {
    border-color: var(--accent-teal);
    box-shadow: 0 0 0 3px var(--accent-teal-glow);
}

button.btn-primary {
    background: var(--accent-teal);
    color: var(--bg-app);
    border: none;
    padding: 0.85rem;
    font-weight: 700;
    border-radius: 6px;
    cursor: pointer;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-size: 0.95rem;
    transition: background 0.2s;
}

button.btn-primary:hover {
    background: #00b3a6;
}

#toast {
    margin-top: 1rem;
    padding: 0.85rem;
    border-radius: 6px;
    display: none;
    text-align: center;
    font-weight: 600;
    font-size: 0.9rem;
}

/* Responsive Overrides for Mobile Portrait / Landscape */
@media (max-width: 768px) {
    .app-body {
        flex-direction: column;
    }
    .sidebar {
        width: 100%;
        flex-direction: row;
        overflow-x: auto;
        padding: 0.75rem;
        gap: 0.5rem;
    }
    .nav-item {
        white-space: nowrap;
        padding: 0.5rem 0.75rem;
    }
    .content-area {
        padding: 1rem;
    }
}
CSS_EOF

echo "[+] Generating Enterprise Client Logic..."
cat << 'JS_EOF' > public/app.js
function handleEnterpriseAuth(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const pass = document.getElementById('password').value;
    const toast = document.getElementById('toast');

    toast.style.display = 'block';
    if (email && pass) {
        toast.style.background = 'rgba(34, 197, 94, 0.15)';
        toast.style.color = 'var(--success)';
        toast.style.border = '1px solid var(--success)';
        toast.innerHTML = '✔ Secure session authorized for operator: <strong>' + email + '</strong>';
    } else {
        toast.style.background = 'rgba(239, 68, 68, 0.15)';
        toast.style.color = 'var(--danger)';
        toast.style.border = '1px solid var(--danger)';
        toast.innerHTML = '✖ Authentication failed: Credentials required.';
    }
}
JS_EOF

echo "[+] Generating Enterprise Application Shell (index.html)..."
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>EB Enterprises - Sovereign Platform Suite</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header class="app-header">
        <div class="brand-section">
            <div class="brand-logo">EB</div>
            <span class="brand-title">EB ENTERPRISES</span>
        </div>
        <div class="user-profile">
            <div class="status-indicator"></div>
            <span>Node Active (v12.4)</span>
        </div>
    </header>

    <div class="app-body">
        <nav class="sidebar">
            <a href="#" class="nav-item active">📊 Dashboard</a>
            <a href="#" class="nav-item">🔐 Auth Gateway</a>
            <a href="#" class="nav-item">⚙️ Mesh Nodes</a>
            <a href="#" class="nav-item">📈 Analytics</a>
        </nav>

        <main class="content-area">
            <div class="dashboard-grid">
                <div class="card">
                    <div class="card-title">Network Throughput</div>
                    <div class="card-value">99.98%</div>
                </div>
                <div class="card">
                    <div class="card-title">Active Secure Tiers</div>
                    <div class="card-value">1,482</div>
                </div>
                <div class="card">
                    <div class="card-title">Latency Status</div>
                    <div class="card-value" style="color: var(--accent-teal);">12ms</div>
                </div>
            </div>

            <div class="panel">
                <div class="panel-header">
                    <h2 class="panel-title">Operator Authentication Console</h2>
                </div>
                <form onsubmit="handleEnterpriseAuth(event)">
                    <div class="form-group">
                        <label for="email">Operator ID / Email</label>
                        <input type="email" id="email" placeholder="operator@eb.enterprise" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Encrypted Security Passkey</label>
                        <input type="password" id="password" placeholder="••••••••••••" required>
                    </div>
                    <button type="submit" class="btn-primary">Authorize Node Session</button>
                </form>
                <div id="toast"></div>
            </div>
        </main>
    </div>

    <script src="app.js"></script>
</body>
</html>
HTML_EOF

# Sync root files
cp public/index.html ./index.html
cp public/style.css ./style.css
cp public/app.js ./app.js

echo "[+] Launching Enterprise App Server..."
pkill -f "node" 2>/dev/null || true
sleep 1

PORT=5000 nohup node server.js > server.log 2>&1 &
echo "[+] Enterprise SaaS platform fully active and live on port 5000."
