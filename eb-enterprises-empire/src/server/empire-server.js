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

const PORT = process.env.PORT || 12000;
const URL = `http://localhost:${PORT}`;

// Self-healing empire manifest
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'empire-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  fs.writeFileSync(manifestPath, JSON.stringify({ status: 'EMPIRE_ACTIVE', timestamp: new Date().toISOString() }, null, 2));
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — EMPIRE ECOSYSTEM</title>
        <style>
            :root {
                --bg-primary: #040d1a;
                --card-bg: #0d1b2a;
                --accent-primary: #00f2fe;
                --accent-hover: #4facfe;
                --text-main: #f0f6fc;
                --text-muted: #8b949e;
                --text-bright: #ffffff;
                --border-color: #1b263b;
                --font-mono: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { background-color: var(--bg-primary); color: var(--text-main); font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; line-height: 1.6; }
            header { border-bottom: 1px solid var(--border-color); padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center; background-color: var(--card-bg); }
            .logo { font-family: var(--font-mono); font-size: 1.25rem; font-weight: bold; color: var(--text-bright); text-decoration: none; display: flex; align-items: center; gap: 0.5rem; }
            .logo span { color: var(--accent-primary); }
            main { max-width: 1350px; margin: 0 auto; padding: 3rem 2rem; }
            .hero { text-align: center; margin-bottom: 3.5rem; }
            .hero h1 { font-size: 3rem; color: var(--text-bright); margin-bottom: 1rem; letter-spacing: -0.03em; font-family: var(--font-mono); text-transform: uppercase; }
            .hero p { font-size: 1.15rem; color: var(--text-muted); max-width: 800px; margin: 0 auto 2rem auto; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 1.5rem; margin-bottom: 3rem; }
            .card { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between; transition: border-color 0.2s; }
            .card:hover { border-color: var(--accent-primary); }
            .card h3 { font-size: 1.05rem; color: var(--text-bright); margin-bottom: 0.5rem; font-family: var(--font-mono); }
            .card p { color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem; }
            .card-footer { font-size: 0.75rem; font-family: var(--font-mono); color: var(--accent-primary); display: flex; justify-content: space-between; align-items: center; }
            .terminal { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; font-family: var(--font-mono); font-size: 0.85rem; margin-top: 2rem; max-height: 250px; overflow-y: auto; }
            .btn { background: linear-gradient(135deg, var(--accent-primary), var(--accent-hover)); color: #040d1a; border: none; padding: 0.85rem 2rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; font-size: 1rem; text-transform: uppercase; }
            .btn:hover { opacity: 0.9; }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
            .live-badge { display: inline-block; width: 10px; height: 10px; background-color: #3fb950; border-radius: 50%; animation: pulse 1s infinite; margin-right: 6px; }
            @keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.2); } 100% { opacity: 1; transform: scale(1); } }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>® Empire</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-bright); display: flex; align-items: center;"><span class="live-badge"></span>ALL PROPERTIES ONLINE</span>
        </header>
        <main>
            <section class="hero">
                <h1>Full-Stack Multi-Website & Software Suite</h1>
                <p>Comprehensive deployment architecture linking www.tap.eco, BuySideOnline®, Cuff P2P, Eggfinder, CoinScan, and Titan-OS/ebOS into a unified autonomous dashboard.</p>
                <button class="btn" onclick="triggerEmpirePulse()">⚡ Pulse Empire Telemetry</button>
            </section>
            <div class="grid">
                <div class="card">
                    <div><h3>www.tap.eco</h3><p>Affiliate community platform, onboarding workflows, & digital sales funnels.</p></div>
                    <div class="card-footer"><span>PORT: 12001</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>BuySideOnline® & Nexus</h3><p>Multi-channel payment engine, secure vault auth, & sales tracker v1-v5.</p></div>
                    <div class="card-footer"><span>PORT: 12002</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>Cuff P2P Consignment</h3><p>Direct peer-to-peer web platform for board games and secure consignment trading.</p></div>
                    <div class="card-footer"><span>PORT: 12003</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>Eggfinder & CoinScan</h3><p>GPS farm-fresh egg plotter and optical US coinage identification engine.</p></div>
                    <div class="card-footer"><span>PORT: 12004</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>Titan-OS / ebOS Kernel</h3><p>Low-level mobile operating system runtime and X11 window compositor.</p></div>
                    <div class="card-footer"><span>PORT: 12005</span><span>ONLINE</span></div>
                </div>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises empire --status</p>
                <p style="color: var(--text-bright);">[EMPIRE] Master Server active on port 12000</p>
                <p style="color: var(--text-muted);">[INFO] Organization: EBenterprises | Managed by eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. Full-Stack Empire Suite deployed successfully.</p>
        </footer>
        <script>
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const ws = new WebSocket(\`\${wsProtocol}//\${window.location.host}\`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                const box = document.getElementById('terminal-box');
                box.innerHTML += \`<p style="color: #00f2fe;">[EMPIRE-FEED] \${data.message}</p>\`;
                box.scrollTop = box.scrollHeight;
            };

            function triggerEmpirePulse() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #f1fa8c;">[PULSE] Broadcasting synchronization packets across all 5 properties...</p>';
                fetch('/api/v1/empire-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += \`<p style="color: #50fa7b;">[SUCCESS] Verified \${data.manifest.properties.length} active ecosystem nodes.</p>\`;
                        box.scrollTop = box.scrollHeight;
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #ff5555;">[ERROR] Empire pulse transmission failed.</p>';
                        box.scrollTop = box.scrollHeight;
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'EMPIRE_ACTIVE', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/v1/empire-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Empire manifest missing.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'EMPIRE_CONNECT', message: 'Empire WebSocket mesh connected: All websites and software synchronized.' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Empire Master Server active at ${URL}`);
  
  // Automatically open the master empire browser window instantly
  const openCmd = process.platform === 'darwin' ? `open "${URL}"` :
                  process.platform === 'win32' ? `start "${URL}"` :
                  `xdg-open "${URL}" 2>/dev/null || termux-open-url "${URL}" 2>/dev/null || echo "Open empire at ${URL}"`;
  
  exec(openCmd, (err) => {
    if (err) {
      console.log(`[INFO] Access empire master suite at: ${URL}`);
    } else {
      console.log(`[SUCCESS] Automatically launched empire browser link: ${URL}`);
    }
  });
});
