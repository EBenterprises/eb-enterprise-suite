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

const PORT = process.env.PORT || 9999;
const URL = `http://localhost:${PORT}`;

// Self-healing show manifest
const distDir = path.join(__dirname, '../../dist');
const manifestPath = path.join(distDir, 'show-manifest.json');
if (!fs.existsSync(distDir)) fs.mkdirSync(distDir, { recursive: true });
if (!fs.existsSync(manifestPath)) {
  fs.writeFileSync(manifestPath, JSON.stringify({ status: 'SHOWTIME_ACTIVE', timestamp: new Date().toISOString() }, null, 2));
}

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EB Enterprises® — LIVE SHOWTIME</title>
        <style>
            :root {
                --bg-primary: #05070c;
                --card-bg: #0d1117;
                --accent-primary: #ff334b;
                --accent-hover: #ff1a35;
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
            .btn { background-color: var(--accent-primary); color: #fff; border: none; padding: 0.85rem 2rem; border-radius: 6px; font-family: var(--font-mono); font-weight: bold; cursor: pointer; display: inline-flex; align-items: center; gap: 0.5rem; font-size: 1rem; text-transform: uppercase; }
            .btn:hover { background-color: var(--accent-hover); }
            footer { border-top: 1px solid var(--border-color); padding: 2rem; text-align: center; color: var(--text-muted); font-size: 0.85rem; background-color: var(--card-bg); margin-top: 4rem; font-family: var(--font-mono); }
            .live-badge { display: inline-block; width: 12px; height: 12px; background-color: var(--accent-primary); border-radius: 50%; animation: pulse 1s infinite; margin-right: 8px; }
            @keyframes pulse { 0% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.2); } 100% { opacity: 1; transform: scale(1); } }
        </style>
    </head>
    <body>
        <header>
            <a href="#" class="logo">⚡ EB<span>Enterprises</span>®</a>
            <span style="font-family: var(--font-mono); font-size: 0.85rem; color: var(--text-bright); display: flex; align-items: center;"><span class="live-badge"></span>LIVE ON AIR // SHOWTIME ACTIVE</span>
        </header>
        <main>
            <section class="hero">
                <h1>Showtime Production Feed</h1>
                <p>The stage is live. Direct automated production feeds, real-time WebRTC streams, and instant multi-channel broadcasts are streaming.</p>
                <button class="btn" onclick="triggerShowtimeAction()">🔴 Engage Live Stream</button>
            </section>
            <div class="grid">
                <div class="card">
                    <div><h3>Titan-OS / ebOS Stream</h3><p>Live mobile kernel rendering & desktop window compositor.</p></div>
                    <div class="card-footer">FEED: 1080P60 // LIVE</div>
                </div>
                <div class="card">
                    <div><h3>BuySideOnline® & Nexus</h3><p>Real-time payment transaction tickers & sales funnels.</p></div>
                    <div class="card-footer">FEED: REAL-TIME // LIVE</div>
                </div>
                <div class="card">
                    <div><h3>TapChat P2P Board Games</h3><p>Direct peer-to-peer data channels & Hangman streams.</p></div>
                    <div class="card-footer">FEED: WEBRTC // LIVE</div>
                </div>
                <div class="card">
                    <div><h3>CoinScan & Eggfinder</h3><p>Fresh farm egg map radar & coin identification scanner.</p></div>
                    <div class="card-footer">FEED: OPTICAL // LIVE</div>
                </div>
            </div>
            <div class="terminal" id="terminal-box">
                <p style="color: var(--accent-primary);">$ eb-enterprises showtime --broadcast</p>
                <p style="color: var(--text-bright);">[BROADCAST] Showtime Server active on port 9999</p>
                <p style="color: var(--text-muted);">[INFO] Organization: EBenterprises | Managed by eastonbodeuxenterprises@gmail.com</p>
            </div>
        </main>
        <footer>
            <p>&copy; 2026 EB Enterprises®. Showtime production in full motion.</p>
        </footer>
        <script>
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const ws = new WebSocket(\`\${wsProtocol}//\${window.location.host}\`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                const box = document.getElementById('terminal-box');
                box.innerHTML += \`<p style="color: #ff334b;">[LIVE-FEED] \${data.message}</p>\`;
            };

            function triggerShowtimeAction() {
                const box = document.getElementById('terminal-box');
                box.innerHTML += '<p style="color: #f0883e;">[BROADCAST] Pushing high-priority frames across all active feeds...</p>';
                fetch('/api/v1/show-manifest')
                    .then(res => res.json())
                    .then(data => {
                        box.innerHTML += \`<p style="color: #3fb950;">[ON AIR] Broadcasting \${data.manifest.productionFeeds.length} feeds successfully.</p>\`;
                    })
                    .catch(err => {
                        box.innerHTML += '<p style="color: #f85149;">[ERROR] Broadcast feed interrupted.</p>';
                    });
            }
        </script>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'SHOWTIME_ACTIVE', uptime: process.uptime(), timestamp: new Date().toISOString() });
});

app.get('/api/v1/show-manifest', (req, res) => {
  if (fs.existsSync(manifestPath)) {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    return res.json({ status: 'SUCCESS', manifest });
  }
  res.status(404).json({ error: 'Show manifest missing.' });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'SHOW_CONNECT', message: 'Showtime WebSocket feed established: On air.' }));
});

server.listen(PORT, () => {
  console.log(`[EB-ENTERPRISES] Showtime Server active at ${URL}`);
  
  // Automatically open the showtime browser window instantly
  const openCmd = process.platform === 'darwin' ? `open "${URL}"` :
                  process.platform === 'win32' ? `start "${URL}"` :
                  `xdg-open "${URL}" 2>/dev/null || termux-open-url "${URL}" 2>/dev/null || echo "Open showtime at ${URL}"`;
  
  exec(openCmd, (err) => {
    if (err) {
      console.log(`[INFO] Access showtime at: ${URL}`);
    } else {
      console.log(`[SUCCESS] Automatically launched showtime link: ${URL}`);
    }
  });
});
