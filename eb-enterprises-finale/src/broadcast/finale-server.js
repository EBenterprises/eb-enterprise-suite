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

const PORT = process.env.PORT || 10000;
const URL = `http://localhost:${PORT}`;

// Self-healing finale manifest
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'finale-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  fs.writeFileSync(manifestPath, JSON.stringify({ status: 'FINALE_ACTIVE', timestamp: new Date().toISOString() }, null, 2));
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — GRAND FINALE</title>
        <style>
            :root {
                --bg-primary: #030508;
                --card-bg: #0d1117;
                --accent-primary: #58a6ff;
                --accent-hover: #79c0ff;
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
            main { max-width: 1300px; margin: 0 auto; padding: 4rem 2rem; }
            .hero { text-align: center; margin-bottom: 4rem; }
            .hero h1 { font-size: 3.5rem; color: var(--text-bright); margin-bottom: 1rem; letter-spacing: -0.03em; font-family: var(--font-mono); text-transform: uppercase; }
            .hero p { font-size: 1.2rem; color: var(--text-muted); max-width: 750px; margin: 0 auto 2rem auto; }
            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 4rem; }
            .card { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between; transition: border-color 0.2s; }
            .card:hover { border-color: var(--accent-primary); }
            .card h3 { font-size: 1.1rem; color: var(--text-bright); margin-bottom: 0.5rem; font-family: var(--font-mono); }
            .card p { color: var(--text-muted); font-size: 0.9rem; margin-bottom: 1rem; }
            .card-footer { font-size: 0.8rem; font-family: var(--font-mono); color: var(--accent-primary); }
            .terminal { background-color: var(--card-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 1.5rem; font-family: var(--font-mono); font-size: 0.9rem; margin-top: 2rem; }
            .btn { background-color: var(--accent-primary); color: #030508; border: none; padding: 0.85rem 2rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; font-size: 1rem; text-transform: uppercase; }
            .btn:hover { background-color: var(--accent-hover); }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
            .live-badge { display: inline-block; width: 12px; height: 12px; background-color: #3fb950; border-radius: 50%; animation: pulse 1s infinite; margin-right: 8px; }
            @keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.2); } 100% { opacity: 1; transform: scale(1); } }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>®</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-bright); display: flex; align-items: center;"><span class="live-badge"></span>GRAND FINALE LIVE ON AIR</span>
        </header>
        <main>
            <section class="hero">
                <h1>Grand Finale Stage</h1>
                <p>All curtains open. Full autonomous orchestration, live WebSocket data pulses, and complete module integration streaming live.</p>
                <button class="btn" onclick="triggerFinaleAction()">⚡ Pulse Live Broadcast</button>
            </section>
            <div class="grid">
                <div class="card">
                    <div><h3>Titan-OS / ebOS</h3><p>Live mobile kernel rendering & window compositor stream.</p></div>
                    <div class="card-footer">STATUS: BROADCASTING</div>
                </div>
                <div class="card">
                    <div><h3>BuySideOnline® & Nexus</h3><p>Real-time payment transaction tickers & affiliate funnels.</p></div>
                    <div class="card-footer">STATUS: BROADCASTING</div>
                </div>
                <div class="card">
                    <div><h3>TapChat & P2P Games</h3><p>Direct peer-to-peer data channels & Hangman streams.</p></div>
                    <div class="card-footer">STATUS: BROADCASTING</div>
                </div>
                <div class="card">
                    <div><h3>CoinScan & Eggfinder</h3><p>Fresh farm egg map radar & coin identification scanner.</p></div>
                    <div class="card-footer">STATUS: BROADCASTING</div>
                </div>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises finale --live</p>
                <p style="color: var(--text-bright);">[BROADCAST] Finale Server active on port 10000</p>
                <p style="color: var(--text-muted);">[INFO] Organization: EBenterprises | Managed by eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. Grand Finale successfully broadcasting.</p>
        </footer>
        <script>
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const ws = new WebSocket(\`\${wsProtocol}//\${window.location.host}\`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                const box = document.getElementById('terminal-box');
                box.innerHTML += \`<p style="color: #58a6ff;">[FINALE-FEED] \${data.message}</p>\`;
            };

            function triggerFinaleAction() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #d29922;">[BROADCAST] Pulsing high-speed packets across all broadcast feeds...</p>';
                fetch('/api/v1/finale-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += \`<p style="color: #3fb950;">[SUCCESS] \${data.manifest.activeBroadcasts.length} broadcasts active and streaming.</p>\`;
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #f85149;">[ERROR] Broadcast pulse interrupted.</p>';
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'FINALE_ACTIVE', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/v1/finale-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Finale manifest missing.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'FINALE_CONNECT', message: 'Grand Finale WebSocket stream connected: On air.' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Grand Finale Server active at ${URL}`);
  
  // Automatically open the grand finale browser window instantly
  const openCmd = process.platform === 'darwin' ? `open "${URL}"` :
                  process.platform === 'win32' ? `start "${URL}"` :
                  `xdg-open "${URL}" 2>/dev/null || termux-open-url "${URL}" 2>/dev/null || echo "Open finale at ${URL}"`;
  
  exec(openCmd, (err) => {
    if (err) {
      console.log(`[INFO] Access grand finale at: ${URL}`);
    } else {
      console.log(`[SUCCESS] Automatically launched grand finale link: ${URL}`);
    }
  });
});
