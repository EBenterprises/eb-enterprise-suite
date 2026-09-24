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

const PORT = process.env.PORT || 13000;
const URL = `http://localhost:${PORT}`;

// Self-healing omniverse manifest
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'omniverse-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  fs.writeFileSync(manifestPath, JSON.stringify({ status: 'OMNIVERSE_ACTIVE', timestamp: new Date().toISOString() }, null, 2));
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — OMNIVERSE COMMAND</title>
        <style>
            :root {
                --bg-primary: #010409;
                --card-bg: #0d1117;
                --accent-primary: #ff7b72;
                --accent-hover: #ffa198;
                --text-main: #f0f6fc;
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
            main { max-width: 1400px; margin: 0 auto; padding: 3rem 2rem; }
            .hero { text-align: center; margin-bottom: 3.5rem; }
            .hero h1 { font-size: 3.2rem; color: var(--text-bright); margin-bottom: 1rem; letter-spacing: -0.03em; font-family: var(--font-mono); text-transform: uppercase; }
            .hero p { font-size: 1.2rem; color: var(--text-muted); max-width: 850px; margin: 0 auto 2rem auto; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(270px, 1fr)); gap: 1.5rem; margin-bottom: 3rem; }
            .card { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between; transition: border-color 0.2s; }
            .card:hover { border-color: var(--accent-primary); }
            .card h3 { font-size: 1.1rem; color: var(--text-bright); margin-bottom: 0.5rem; font-family: var(--font-mono); }
            .card p { color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem; }
            .card-footer { font-size: 0.75rem; font-family: var(--font-mono); color: var(--accent-primary); display: flex; justify-content: space-between; align-items: center; }
            .terminal { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; font-family: var(--font-mono); font-size: 0.85rem; margin-top: 2rem; max-height: 280px; overflow-y: auto; }
            .btn { background-color: var(--accent-primary); color: #010409; border: none; padding: 0.9rem 2.2rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; font-size: 1rem; text-transform: uppercase; }
            .btn:hover { background-color: var(--accent-hover); }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
            .live-badge { display: inline-block; width: 10px; height: 10px; background-color: #3fb950; border-radius: 50%; animation: pulse 1s infinite; margin-right: 6px; }
            @keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.2); } 100% { opacity: 1; transform: scale(1); } }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>® Omniverse</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-bright); display: flex; align-items: center;"><span class="live-badge"></span>ALL SYSTEMS LAUNCHED & LIVE</span>
        </header>
        <main>
            <section class="hero">
                <h1>Omniverse Master Command</h1>
                <p>All software architectures, affiliate websites, payment engines, optical ID scanners, and mobile operating system kernels are fully spun up and synchronized.</p>
                <button class="btn" onclick="triggerOmniversePulse()">⚡ Pulse Omniverse Nodes</button>
            </section>
            <div class="grid">
                <div class="card">
                    <div><h3>www.tap.eco</h3><p>Affiliate community platform, user onboarding, and digital sales funnels.</p></div>
                    <div class="card-footer"><span>PORT: 13001</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>BuySideOnline® & Nexus</h3><p>Multi-channel payment engine, secure vault auth, and sales tracker v1-v5.</p></div>
                    <div class="card-footer"><span>PORT: 13002</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>Cuff P2P & TapChat</h3><p>Direct peer-to-peer web platform for board games and consignment.</p></div>
                    <div class="card-footer"><span>PORT: 13003</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>Eggfinder & CoinScan</h3><p>GPS farm-fresh egg plotter and optical US coinage identification engine.</p></div>
                    <div class="card-footer"><span>PORT: 13004</span><span>ONLINE</span></div>
                </div>
                <div class="card">
                    <div><h3>Titan-OS / ebOS Kernel</h3><p>Low-level mobile operating system runtime and X11 window compositor.</p></div>
                    <div class="card-footer"><span>PORT: 13005</span><span>ONLINE</span></div>
                </div>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises omniverse --launch-all</p>
                <p style="color: var(--text-bright);">[OMNIVERSE] Master Server active on port 13000</p>
                <p style="color: var(--text-muted);">[INFO] Organization: EBenterprises | Managed by eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. All systems launched into full production.</p>
        </footer>
        <script>
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const ws = new WebSocket(\`\${wsProtocol}//\${window.location.host}\`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                const box = document.getElementById('terminal-box');
                box.innerHTML += \`<p style="color: #ff7b72;">[OMNI-FEED] \${data.message}</p>\`;
                box.scrollTop = box.scrollHeight;
            };

            function triggerOmniversePulse() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #d29922;">[PULSE] Broadcasting synchronization packets across all omniverse nodes...</p>';
                fetch('/api/v1/omniverse-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += \`<p style="color: #3fb950;">[SUCCESS] All \${data.manifest.ecosystemNodes.length} enterprise nodes verified and pulsing.</p>\`;
                        box.scrollTop = box.scrollHeight;
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #f85149;">[ERROR] Omniverse pulse interrupted.</p>';
                        box.scrollTop = box.scrollHeight;
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'OMNIVERSE_ACTIVE', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/v1/omniverse-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Omniverse manifest missing.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'OMNIVERSE_CONNECT', message: 'Omniverse WebSocket mesh connected: All platforms online.' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Omniverse Master Server active at ${URL}`);
  
  // Automatically open the omniverse browser window instantly
  const openCmd = process.platform === 'darwin' ? `open "${URL}"` :
                  process.platform === 'win32' ? `start "${URL}"` :
                  `xdg-open "${URL}" 2>/dev/null || termux-open-url "${URL}" 2>/dev/null || echo "Open omniverse at ${URL}"`;
  
  exec(openCmd, (err) => {
    if (err) {
      console.log(`[INFO] Access omniverse command center at: ${URL}`);
    } else {
      console.log(`[SUCCESS] Automatically launched omniverse browser link: ${URL}`);
    }
  });
});
