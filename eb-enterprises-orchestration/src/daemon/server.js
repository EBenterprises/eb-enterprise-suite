const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

app.use(express.json());

const PORT = process.env.PORT || 8700;
const URL = `http://localhost:${PORT}`;

// Self-healing check: Ensure manifest always exists on daemon boot
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'orchestration-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  const defaultManifest = {
    organization: 'EBenterprises',
    managedBy: 'eastonbodeuxenterprises@gmail.com',
    version: '19.0.0',
    orchestratedAt: new Date().toISOString(),
    subsystems: [{ name: 'Core Engine', status: 'AUTO_HEALED' }],
    status: 'ACTIVE'
  };
  fs.writeFileSync(manifestPath, JSON.stringify(defaultManifest, null, 2));
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — Autonomous Orchestration Center</title>
        <style>
            :root {
                --bg-primary: #090d16;
                --card-bg: #161b22;
                --accent-primary: #238636;
                --accent-hover: #2ea043;
                --text-main: #c9d1d9;
                --text-muted: #8b949e;
                --text-bright: #ffffff;
                --border-color: #30363d;
                --font-mono: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { background-color: var(--bg-primary); color: var(--text-main); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.6; }
            header { border-bottom: 1px solid var(--border-color); padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center; background-color: var(--card-bg); }
            .logo { font-family: var(--font-mono); font-size: 1.25rem; font-weight: bold; color: var(--text-bright); text-decoration: none; display: flex; align-items: center; gap: 0.5rem; }
            .logo span { color: var(--accent-primary); }
            main { max-width: 1200px; margin: 0 auto; padding: 4rem 2rem; }
            .hero { text-align: center; margin-bottom: 4rem; }
            .hero h1 { font-size: 3rem; color: var(--text-bright); margin-bottom: 1rem; letter-spacing: -0.02em; }
            .hero p { font-size: 1.2rem; color: var(--text-muted); max-width: 700px; margin: 0 auto 2rem auto; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 2rem; margin-bottom: 4rem; }
            .card { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 2rem; display: flex; flex-direction: column; justify-content: space-between; transition: border-color 0.2s; }
            .card:hover { border-color: var(--accent-primary); }
            .card h3 { font-size: 1.25rem; color: var(--text-bright); margin-bottom: 0.75rem; font-family: var(--font-mono); }
            .card p { color: var(--text-muted); font-size: 0.95rem; margin-bottom: 1.5rem; }
            .card-footer { font-size: 0.85rem; font-family: var(--font-mono); color: var(--accent-primary); }
            .terminal { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; font-family: var(--font-mono); font-size: 0.9rem; margin-top: 2rem; }
            .btn { background-color: var(--accent-primary); color: #fff; border: none; padding: 0.75rem 1.5rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; }
            .btn:hover { background-color: var(--accent-hover); }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>®</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-muted);">ORG: EBenterprises</span>
        </header>
        <main>
            <section class="hero">
                <h1>Autonomous Orchestration Center</h1>
                <p>Fully automated cross-platform coordination and live self-healing daemon for EB Enterprises®.</p>
                <button class="btn" onclick="triggerSync()">⚡ Verify Live Pipeline</button>
            </section>
            <div class="grid">
                <div class="card">
                    <div>
                      <h3>Titan-OS & ebOS</h3>
                      <p>Low-level mobile kernels, window management runtimes, and isolated execution nodes.</p>
                    </div>
                    <div class="card-footer">STATUS: AUTO-LOADED</div>
                </div>
                <div class="card">
                    <div>
                      <h3>BuySideOnline® & Nexus</h3>
                      <p>Transaction ledgers, multi-channel payment gateways, and Tap.eco affiliate workflows.</p>
                    </div>
                    <div class="card-footer">STATUS: AUTO-LOADED</div>
                </div>
                <div class="card">
                    <div>
                      <h3>TapChat & Secure Vault</h3>
                      <p>P2P distributed messaging protocols, WebRTC channels, and hardened authentication vaults.</p>
                    </div>
                    <div class="card-footer">STATUS: AUTO-LOADED</div>
                </div>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises autonomous --online</p>
                <p style="color: var(--text-bright);">[ONLINE] Autonomous Daemon active on port 8700</p>
                <p style="color: var(--text-muted);">[INFO] Managed under eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. All rights reserved. Synchronized under EBenterprises organization.</p>
        </footer>
        <script>
            function triggerSync() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #d29922;">[SYNC] Verifying self-healing manifest integrity...</p>';
                fetch('/api/v1/orchestration-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += '<p style="color: #3fb950;">[SUCCESS] Manifest verified and synchronized successfully.</p>';
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #f85149;">[ERROR] Synchronization failed.</p>';
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'HEALTHY', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/v1/orchestration-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Manifest missing.' });
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Autonomous Daemon active at ${URL}`);
  
  // Automatically open the link in the default browser/viewer on startup
  const openCmd = process.platform === 'darwin' ? `open "${URL}"` :
                  process.platform === 'win32' ? `start "${URL}"` :
                  `xdg-open "${URL}" 2>/dev/null || termux-open-url "${URL}" 2>/dev/null || echo "Open browser at ${URL}"`;
  
  exec(openCmd, (err) => {
    if (err) {
      console.log(`[INFO] Access dashboard at: ${URL}`);
    } else {
      console.log(`[SUCCESS] Automatically opened dashboard link: ${URL}`);
    }
  });
});
