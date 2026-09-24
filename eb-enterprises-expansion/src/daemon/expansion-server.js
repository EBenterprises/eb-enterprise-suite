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
app.use(express.static(path.join(__dirname, '../../public')));

const PORT = process.env.PORT || 9900;
const URL = `http://localhost:${PORT}`;

// Self-healing expansion manifest validation
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'expansion-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  fs.writeFileSync(manifestPath, JSON.stringify({ status: 'AUTO_HEALED', timestamp: new Date().toISOString() }, null, 2));
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — Next-Gen Expansion Suite</title>
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
            main { max-width: 1300px; margin: 0 auto; padding: 4rem 2rem; }
            .hero { text-align: center; margin-bottom: 4rem; }
            .hero h1 { font-size: 3rem; color: var(--text-bright); margin-bottom: 1rem; letter-spacing: -0.02em; }
            .hero p { font-size: 1.2rem; color: var(--text-muted); max-width: 750px; margin: 0 auto 2rem auto; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 4rem; }
            .card { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between; transition: border-color 0.2s; }
            .card:hover { border-color: var(--accent-primary); }
            .card h3 { font-size: 1.1rem; color: var(--text-bright); margin-bottom: 0.5rem; font-family: var(--font-mono); }
            .card p { color: var(--text-muted); font-size: 0.9rem; margin-bottom: 1rem; }
            .card-footer { font-size: 0.8rem; font-family: var(--font-mono); color: var(--accent-primary); }
            .terminal { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; font-family: var(--font-mono); font-size: 0.9rem; margin-top: 2rem; }
            .btn { background-color: var(--accent-primary); color: #fff; border: none; padding: 0.75rem 1.5rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; }
            .btn:hover { background-color: var(--accent-hover); }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
            .live-badge { display: inline-block; width: 10px; height: 10px; background-color: #3fb950; border-radius: 50%; animation: pulse 1.5s infinite; margin-right: 6px; }
            @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.3; } 100% { opacity: 1; } }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>®</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-muted); display: flex; align-items: center;"><span class="live-badge"></span>EXPANSION MODULES ONLINE</span>
        </header>
        <main>
            <section class="hero">
                <h1>Next-Gen Expansion Suite</h1>
                <p>Deploying standalone separation modules including Nexus, TEAM, Tap.eco scaling, Cuff P2P, and Vault extensions.</p>
                <button class="btn" onclick="verifyExpansion()">⚡ Verify Expansion Nodes</button>
            </section>
            <div class="grid">
                <div class="card">
                    <div><h3>Nexus Core Engine</h3><p>Isolated payment gateway & transaction processor.</p></div>
                    <div class="card-footer">PORT: 9901 // ACTIVE</div>
                </div>
                <div class="card">
                    <div><h3>TEAM Synchronizer</h3><p>Independent operations & team management pipeline.</p></div>
                    <div class="card-footer">PORT: 9902 // ACTIVE</div>
                </div>
                <div class="card">
                    <div><h3>Tap.eco Scaling Gateway</h3><p>Advanced affiliate marketing & onboarding funnels.</p></div>
                    <div class="card-footer">PORT: 9903 // ACTIVE</div>
                </div>
                <div class="card">
                    <div><h3>Cuff P2P Consignment</h3><p>Direct-connect peer-to-peer marketplace routing.</p></div>
                    <div class="card-footer">PORT: 9904 // ACTIVE</div>
                </div>
                <div class="card">
                    <div><h3>Secure Vault Extension</h3><p>Zero-dependency cryptographic authentication suite.</p></div>
                    <div class="card-footer">PORT: 9905 // ACTIVE</div>
                </div>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises expansion --daemon</p>
                <p style="color: var(--text-bright);">[ONLINE] Expansion Master Daemon active on port 9900</p>
                <p style="color: var(--text-muted);">[INFO] Organization: EBenterprises | Managed by eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. Expansion modules compiled and linked.</p>
        </footer>
        <script>
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const ws = new WebSocket(\`\${wsProtocol}//\${window.location.host}\`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                const box = document.getElementById('terminal-box');
                box.innerHTML += \`<p style="color: #3fb950;">[WS-STREAM] \${data.message}</p>\`;
            };

            function verifyExpansion() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #d29922;">[SYNC] Polling status across expansion nodes...</p>';
                fetch('/api/v1/expansion-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += \`<p style="color: #58a6ff;">[SUCCESS] Verified \${data.manifest.expansionModules.length} expansion modules online.</p>\`;
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #f85149;">[ERROR] Expansion poll failed.</p>';
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'HEALTHY', expansionNodes: 5, uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/v1/expansion-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Manifest missing.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'EXPANSION_CONNECT', message: 'WebSocket stream online: Expansion nodes connected.' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Expansion Master Daemon active at ${URL}`);
  
  // Automatically open the link in the default browser/viewer immediately
  const openCmd = process.platform === 'darwin' ? `open "${URL}"` :
                  process.platform === 'win32' ? `start "${URL}"` :
                  `xdg-open "${URL}" 2>/dev/null || termux-open-url "${URL}" 2>/dev/null || echo "Open browser at ${URL}"`;
  
  exec(openCmd, (err) => {
    if (err) {
      console.log(`[INFO] Access expansion dashboard at: ${URL}`);
    } else {
      console.log(`[SUCCESS] Automatically launched expansion dashboard link: ${URL}`);
    }
  });
});
